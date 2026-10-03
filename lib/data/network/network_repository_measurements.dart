part of 'network_repository_impl.dart';

extension NetworkRepositoryMeasurements
    on NetworkRepositoryImpl {
  Future<double> _measureIdlePing() async {
    return await dataSource.measureIdlePing() ??
        9999.0;
  }

  Future<double> _measureDownloadSpeed() async {
    return await dataSource.measureDownloadSpeed() ??
        0.0;
  }

  Future<double> _measureDownloadPing() async {
    return await dataSource.measureDownloadPing() ??
        9999.0;
  }

  Future<double> _measureUploadSpeed() async {
    return await dataSource.measureUploadSpeed() ??
        0.0;
  }

  Future<double> _measureUploadPing() async {
    return await dataSource.measureUploadPing() ??
        9999.0;
  }

  Future<double> _measurePacketLoss() async {
    return await dataSource.measurePacketLoss() ??
        100.0;
  }
}