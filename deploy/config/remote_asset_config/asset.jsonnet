{
  fetcher: {
    caching: {
      fetcher: {
        http: {
          allowUpdatesForInstances: ['remote-execution'],
          contentAddressableStorage: {
            grpc: {
              address: "frontend:8980"
  }}}}}},


  assetCache: {
    blobAccess: {
      assetStore: {
        'local': {
          keyLocationMapOnBlockDevice: {
            file: {
              path: '/storage/key_location_map',
              sizeBytes: 1024 * 1024,
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
                path: '/storage/blocks',
                sizeBytes: 100 * 1024 * 1024,
              },
            },
            spareBlocks: 3,
          },
          #
          # Add this chunk if you also want it to be persistent across restarts. If no persistency is needed, just omit this.
          # persistent: {
          #   stateDirectoryPath: '/storage/persistent_state',
          #   minimumEpochInterval: '5m',
          # },
          #
        },
      },
      contentAddressableStorage: {
        grpc: {
          address: "frontend:8980"
        }
      }
    },
  },
  global: { diagnosticsHttpListenAddress: ':7982' },
  grpcServers: [{
    listenAddresses: [':8979'],
    authenticationPolicy: { allow: {} },
  }],
  allowUpdatesForInstances: ['remote-execution'],
  maximumMessageSizeBytes: 16 * 1024 * 1024 * 1024,
}
