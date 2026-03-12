import 'package:delivery_express_mobility_frontend/features/client/presentation/pages/client_home_page.dart';
import 'package:flutter/material.dart';

class ClientHomeEntryPage extends StatelessWidget {
  final String? userName;

  const ClientHomeEntryPage({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    return ClientHomePage(userName: userName);
  }
}
