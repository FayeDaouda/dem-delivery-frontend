import 'package:flutter/widgets.dart';

import 'package:delivery_express_mobility_frontend/features/driver_vtc/presentation/pages/driver_vtc_home_page.dart';

/// Wrapper léger : le home MOTO réutilise l'UI du home VTC.
class DriverMotoHomePage extends StatelessWidget {
  final String? driverName;
  final String? driverId;

  const DriverMotoHomePage({Key? key, this.driverName, this.driverId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DriverVtcHomePage(
      driverName: driverName,
      driverId: driverId,
    );
  }
}

typedef LivreurHomePage = DriverVtcHomePage;
