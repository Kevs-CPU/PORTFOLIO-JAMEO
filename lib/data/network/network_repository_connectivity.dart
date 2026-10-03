part of 'network_repository_impl.dart';

extension NetworkRepositoryConnectivity
    on NetworkRepositoryImpl {
  Future<NetworkStatus> _getCurrentNetwork() async {
    final List<ConnectivityResult> connectivity =
        await dataSource.getCurrentConnectivity();

    return _mapConnectivity(connectivity);
  }

  Stream<NetworkStatus> _watchNetwork() {
    return dataSource
        .watchConnectivity()
        .map(_mapConnectivity);
  }

  NetworkStatus _mapConnectivity(
    List<ConnectivityResult> connectivity,
  ) {
    if (connectivity.contains(
      ConnectivityResult.wifi,
    )) {
      return const NetworkStatus(
        type: NetworkType.wifi,
      );
    }

    if (connectivity.contains(
      ConnectivityResult.mobile,
    )) {
      return const NetworkStatus(
        type: NetworkType.cellular,
      );
    }

    return const NetworkStatus(
      type: NetworkType.offline,
    );
  }
}