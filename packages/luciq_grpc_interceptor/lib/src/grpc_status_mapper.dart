/// Maps a gRPC status code to an approximate HTTP status code
/// for dashboard compatibility.
int grpcStatusToHttpStatus(int grpcStatus) {
  switch (grpcStatus) {
    case 0:
      return 200; // OK
    case 1:
      return 499; // CANCELLED
    case 2:
      return 500; // UNKNOWN
    case 3:
      return 400; // INVALID_ARGUMENT
    case 4:
      return 504; // DEADLINE_EXCEEDED
    case 5:
      return 404; // NOT_FOUND
    case 6:
      return 409; // ALREADY_EXISTS
    case 7:
      return 403; // PERMISSION_DENIED
    case 8:
      return 429; // RESOURCE_EXHAUSTED
    case 9:
      return 400; // FAILED_PRECONDITION
    case 10:
      return 409; // ABORTED
    case 11:
      return 400; // OUT_OF_RANGE
    case 12:
      return 501; // UNIMPLEMENTED
    case 13:
      return 500; // INTERNAL
    case 14:
      return 503; // UNAVAILABLE
    case 15:
      return 500; // DATA_LOSS
    case 16:
      return 401; // UNAUTHENTICATED
    default:
      return 500;
  }
}
