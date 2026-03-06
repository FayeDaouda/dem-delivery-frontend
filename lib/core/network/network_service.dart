import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
