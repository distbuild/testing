local common = import 'common.libsonnet';

{
  global: { diagnosticsHttpServer: {
    listenAddress: ':7982',
    enablePrometheus: true,
    enablePprof: true,
  } },
  adminHttpListenAddress: ':12345',
  clientGrpcServers: [{
    listenAddresses: [':8982'],
    authenticationPolicy: { allow: {} },
  }],
  workerGrpcServers: [{
    listenAddresses: [':8983'],
    authenticationPolicy: { allow: {} },
  }],
  executeAuthorizer: { allow: {} },
  browserUrl: common.browserUrl,
  contentAddressableStorage: common.blobstore.contentAddressableStorage,
  maximumMessageSizeBytes: common.maximumMessageSizeBytes,
  defaultExecutionTimeout: '1800s',
  maximumExecutionTimeout: '3600s',
}
