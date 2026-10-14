/// Model typed untuk state async pada setiap modul aplikasi SIMKlinik.
/// Memastikan setiap layar menangani state secara lengkap:
/// Loading, Success, Empty, Error, Offline, dan Permission Denied.
sealed class ApiResult<T> {
  const ApiResult();
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

class ApiLoading<T> extends ApiResult<T> {
  const ApiLoading();
}

class ApiEmpty<T> extends ApiResult<T> {
  final String message;
  const ApiEmpty({this.message = 'Tidak ada data ditemukan'});
}

class ApiError<T> extends ApiResult<T> {
  final String message;
  final String? code;
  final bool isOffline;
  final bool isPermissionDenied;

  const ApiError({
    required this.message,
    this.code,
    this.isOffline = false,
    this.isPermissionDenied = false,
  });
}
