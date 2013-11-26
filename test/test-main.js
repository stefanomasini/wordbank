var tests = [];
for (var file in window.__karma__.files) {
    if (window.__karma__.files.hasOwnProperty(file)) {
        if (/Spec\.js$/.test(file)) {
            tests.push(file);
        }
    }
}

require.config({
    baseUrl: '/base/static',

    paths: {
        lib: 'lib',

        // Aliases for libraries, so that we can change versions from here
        libreact: '../bower_components/react/react.min',
        JSXTransformer: '../bower_components/react/JSXTransformer',
        jsx: '../lib/require-jsx',
        jquery: '../bower_components/jquery/jquery.min',
        lodash: '../bower_components/lodash/dist/lodash.min'
    },

    shim: {
        JSXTransformer: {
            exports: "JSXTransformer"
        }
    },

    packages: [{
        name: 'cs',
        location: 'bower_components/require-cs',
        main: 'cs'
    }, {
        name: 'coffee-script',
        location: 'bower_components/coffee-script',
        main: 'index'
    }],

    // This is appended to every module loading request, for cache invalidation purposes
//    urlArgs: "bust=" + (new Date()).getTime(),

    // ask Require.js to load these files (all our tests)
    deps: tests,

    // start test run, once Require.js is done
    callback: window.__karma__.start
});
