# Luciq Dio Interceptor

[![CircleCI](https://circleci.com/gh/Luciq/Luciq-Dio-Interceptor.svg?style=svg)](https://circleci.com/gh/Luciq/Luciq-Dio-Interceptor)
[![pub package](https://img.shields.io/pub/v/luciq_dio_interceptor.svg)](https://pub.dev/packages/luciq_dio_interceptor)

This package is an add on to [Luciq-Flutter](https://github.com/luciqai/luciq-flutter-sdk).

It intercepts any requests performed with `Dio` Package and sends them to the report that will be sent to the dashboard.  

## Integration

To enable network logging, simply add the  `LuciqDioInterceptor` to the dio object interceptors as follows:

```dart
var dio = new Dio();
dio.interceptors.add(LuciqDioInterceptor());
```
