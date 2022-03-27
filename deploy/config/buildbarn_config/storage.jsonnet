local common = import 'common.libsonnet';

{
  blobstore: {
    contentAddressableStorage: {
      'local': {
        keyLocationMapOnBlockDevice: {
          file: {
            path: '/storage-cas/key_location_map',
            sizeBytes: 16 * 1024 * 1024,
          },
        },
        keyLocationMapMaximumGetAttempts: 8,
        keyLocationMapMaximumPutAttempts: 32,
        oldBlocks: 8,
        currentBlocks: 24,
        newBlocks: 3,
        blocksOnBlockDevice: {
          source: {
            file: {
              path: '/storage-cas/blocks',
              sizeBytes: 10 * 1024 * 1024 * 1024,
            },
          },
          spareBlocks: 3,
        },
        persistent: {
          stateDirectoryPath: '/storage-cas/persistent_state',
          minimumEpochInterval: '300s',
        },
      },
    },
    actionCache: {
      completenessChecking: {
          'local': {
          keyLocationMapOnBlockDevice: {
            file: {
              path: '/storage-ac/key_location_map',
              sizeBytes: 1024 * 1024,
            },
          },
          keyLocationMapMaximumGetAttempts: 8,
          keyLocationMapMaximumPutAttempts: 32,
          oldBlocks: 8,
          currentBlocks: 24,
          newBlocks: 1,
          blocksOnBlockDevice: {
            source: {
              file: {
                path: '/storage-ac/blocks',
                sizeBytes: 100 * 1024 * 1024,
              },
            },
            spareBlocks: 3,
          },
          persistent: {
            stateDirectoryPath: '/storage-ac/persistent_state',
            minimumEpochInterval: '300s',
          },
        },
      },
    },
  },
  global: { diagnosticsHttpServer: {
    listenAddress: ':7981',
    enablePrometheus: true,
    enablePprof: true,
  } },
  grpcServers: [{
    listenAddresses: [':8981'],
    authenticationPolicy: { allow: {} },
  }],
  contentAddressableStorageAuthorizers: {
    get: { allow: {} },
    put: { allow: {} },
    findMissing: { allow: {} },
  },
  actionCacheAuthorizers: {
    get: { allow: {} },
    put: { instanceNamePrefix: {
      allowedInstanceNamePrefixes: [''],
    } },
  },
  executeAuthorizer: { allow: {} },
  maximumMessageSizeBytes: common.maximumMessageSizeBytes,
}
