part of 'network_repository_impl.dart';

extension NetworkRepositoryLifecycle
    on NetworkRepositoryImpl {
  Future<void> _startLiveMonitoring() async {
    await dataSource.startLiveMonitoring();
  }

  Future<void> _stopLiveMonitoring() async {
    await dataSource.stopLiveMonitoring();
  }
}