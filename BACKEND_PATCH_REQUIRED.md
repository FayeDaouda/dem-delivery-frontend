# 🔧 Patch Backend - Schéma DB vs Code

## 🔴 PROBLÈME ACTUEL: Colonne `user_id` n'existe pas

```
column "user_id" does not exist
```

**Logs récents:**
```
passes.driver introuvable, fallback sur passes.user_id
→ QueryFailedError: column "user_id" does not exist
```

## Cause Racine

Le **schéma DB** utilise la colonne `driver`, mais le **code** fait encore des requêtes SQL avec `user_id`:

```sql
-- ❌ Ce que le code fait:
SELECT * FROM passes WHERE user_id = $1

-- ✅ Ce qu'il devrait faire:
SELECT * FROM passes WHERE driver = $1
```

**Timeline des erreurs:**
1. Tentative 1: `user_id` null → Colonne mal assignée
2. Tentative 2: `pass_type` null → Colonne mal mappée  
3. Tentative 3: `user_id` does not exist → **Nom de colonne incorrect dans SQL**

## 📊 Schéma Réel de la Table `passes`

```sql
CREATE TABLE passes (
  id                      UUID PRIMARY KEY,
  driver                  UUID NOT NULL,          -- ✅ PAS user_id
  type                    VARCHAR NOT NULL,       -- ou pass_type
  price                   INTEGER NOT NULL,
  status                  VARCHAR NOT NULL,
  valid_from              TIMESTAMP NOT NULL,
  valid_until             TIMESTAMP NOT NULL,
  payment_method          VARCHAR NOT NULL,
  payment_transaction_id  UUID,
  created_at              TIMESTAMP DEFAULT NOW(),
  updated_at              TIMESTAMP DEFAULT NOW()
);
```

**Colonne critique:** `driver` (UUID) - référence vers `users.id`

---

## 🔧 Corrections à Appliquer

### 1️⃣ PassesService.getCurrentPass()

**Fichier:** `src/modules/passes/passes.service.ts`

**Avant (❌):**
```typescript
const pass = await this.dataSource.query(
  `
  SELECT *
  FROM passes
  WHERE user_id = $1    -- ❌ Colonne n'existe pas
  AND status = 'active'
  ORDER BY valid_until DESC
  LIMIT 1
  `,
  [userId],
);
```

**Après (✅):**
```typescript
const pass = await this.dataSource.query(
  `
  SELECT *
  FROM passes
  WHERE driver = $1     -- ✅ Colonne correcte
  AND status = 'active'
  ORDER BY valid_until DESC
  LIMIT 1
  `,
  [userId],
);
```

---

### 2️⃣ PurchasePassUseCase - Vérification Pass Existant

**Fichier:** `src/modules/passes/usecases/purchase-pass.usecase.ts` (ligne ~97)

**Avant (❌):**
```typescript
const existingPass = await this.dataSource.query(
  `
  SELECT id
  FROM passes
  WHERE user_id = $1    -- ❌ Colonne n'existe pas
  AND status = 'active'
  LIMIT 1
  `,
  [driverId],
);
```

**Après (✅):**
```typescript
const existingPass = await this.dataSource.query(
  `
  SELECT id
  FROM passes
  WHERE driver = $1     -- ✅ Colonne correcte
  AND status = 'active'
  LIMIT 1
  `,
  [driverId],
);
```

---

### 3️⃣ Entité Pass - Mapping TypeORM

**Fichier:** `src/modules/passes/entities/pass.entity.ts`

**Vérifier que l'entité mappe correctement:**

```typescript
import { Column, Entity, PrimaryGeneratedColumn, ManyToOne, JoinColumn } from 'typeorm';
import { UserEntity } from '../../users/entities/user.entity';

@Entity('passes')
export class Pass {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // ✅ MAPPING CORRECT
  @Column({ name: 'driver', type: 'uuid' })
  driver: string;  // ← NOM CORRECT
  
  @Column({ name: 'type', type: 'varchar' })  // ou 'pass_type' si c'est le nom en DB
  type: string;
  
  @Column({ type: 'integer' })
  price: number;
  
  @Column({ type: 'varchar' })
  status: string;
  
  @Column({ name: 'valid_from', type: 'timestamp' })
  validFrom: Date;
  
  @Column({ name: 'valid_until', type: 'timestamp' })
  validUntil: Date;
  
  @Column({ name: 'payment_method', type: 'varchar' })
  paymentMethod: string;
  
  @Column({ name: 'payment_transaction_id', type: 'uuid', nullable: true })
  paymentTransactionId?: string;
  
  // Relation optionnelle
  @ManyToOne(() => UserEntity, { eager: false })
  @JoinColumn({ name: 'driver' })
  driverUser?: UserEntity;
}
```

---

### 4️⃣ Supprimer le Fallback sur `user_id`

**Supprimer ce code partout:**
```typescript
// ❌ À SUPPRIMER
try {
  WHERE driver = $1
} catch {
  // Fallback sur user_id
  WHERE user_id = $1  // ← Cette colonne n'existe plus !
}
```

**Logs à éliminer:**
```
passes.driver introuvable, fallback sur passes.user_id
```

---

## 📝 Checklist de Correction

- [ ] **PassesService.getCurrentPass()** → Remplacer `user_id` par `driver`
- [ ] **PurchasePassUseCase (ligne 97)** → Remplacer `user_id` par `driver`
- [ ] **Toutes les requêtes SQL brutes** → Rechercher globalement `user_id` et remplacer par `driver`
- [ ] **Entité Pass** → Vérifier `@Column({ name: 'driver' })`
- [ ] **Supprimer fallback** → Enlever tout code qui essaie `user_id` en fallback
- [ ] **Vérifier le schéma** → `\d passes` dans psql pour confirmer les noms de colonnes

---

## 🧪 Commande de Vérification (Render)

Pour confirmer les colonnes de ta table:

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'passes'
ORDER BY ordinal_position;
```

Résultat attendu:
```
 column_name              | data_type | is_nullable
--------------------------+-----------+-------------
 id                       | uuid      | NO
 driver                   | uuid      | NO          ← Pas user_id
 type                     | varchar   | NO
 price                    | integer   | NO
 ...
```

---

## ✅ Après Correction - Test Attendu

**Backend logs (succès):**
```
✅ POST /passes/purchase
✅ Driver e35c094b... purchasing daily pass
✅ Pass created with driver=e35c094b...
✅ Response 201 { "pass": { "id": "...", "validUntil": "..." }, "transaction": {...} }
```

**Frontend:**
```
✅ PassActivationSuccess state
✅ Toast "Pass Activé 🎉"
✅ Countdown démarre "23h 59m"
✅ GET /passes/current polling fonctionne
```

---

## 💡 Pourquoi `driver` est meilleur que `user_id`

Ton architecture:
```
users
 ├─ clients   (rôle: customer)
 ├─ drivers   (rôle: driver)
 └─ admins    (rôle: admin)
```

La colonne `driver` rend explicite que seuls les drivers ont des passes.  
C'est un bon choix d'architecture ✅

---

## 🚀 Frontend Status: PRÊT

Le frontend envoie déjà le **bon payload**. Zero changement nécessaire.

Dès que le backend utilise `driver` au lieu de `user_id`, tout fonctionnera 🎯
