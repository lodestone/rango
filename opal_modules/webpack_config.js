const path = require('path');
const OwlResolver = require('opal-webpack-loader/resolver'); // to resolve ruby files

const common_config = {
    mode: 'production',
    optimization: {
        minimize: true
    },
    performance: {
        maxAssetSize: 20000000,
        maxEntrypointSize: 20000000
    },
    output: {
        path: path.resolve(__dirname, '..'),
        filename: '[name].js',
        libraryTarget: 'var',
        // globalObject: 'this',
        // libraryExport: 'default',
        library: '[name]'
    },
    resolve: {
        plugins: [
            // this makes it possible for webpack to find ruby files
            new OwlResolver('resolve', 'resolved')
        ]
    },
    module: {
        rules: [
            {
                test: /\.(js)$/,
                exclude: /(node_modules)/
            },
            {
                // opal-webpack-loader will compile and include ruby files in the pack
                test:  /(\.js)?\.rb$/,
                use: [
                    {
                        loader: 'opal-webpack-loader',
                        options: {
                            sourceMap: false,
                            hmr: false,
                            hmrHook: ''
                        }
                    }
                ]
            }
        ]
    }
};

const node_config = {
    target: 'node',
    entry: {
        arango_opal: path.resolve(__dirname, 'entry_opal_node.js'),
        arango_opal_parser: path.resolve(__dirname, 'entry_opal_parser.js'),
    }
};

const node = Object.assign({}, common_config, node_config);

module.exports = [ node ];