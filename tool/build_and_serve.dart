import 'dart:io';
import 'package:flutter_154620/routes.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

const flutterBin = r'C:\\Dev\\Google\\Flutter\\Flutter main\\bin\\flutter.bat';

Future<void> main() async {
  print('Building web app...');
  final proc = await Process.start(flutterBin, ['build', 'web']);
  proc.stdout.listen(stdout.add);
  proc.stderr.listen(stdout.add);

  if (await proc.exitCode != 0) {
    print('Build failed');
    exit(1);
  }

  const proxyPrefix = 'proxy/1234/';
  final indexPages = {
    '',
    for (var route in routes) route.substring(1),
  };

  final staticHandler = shelf_static.createStaticHandler(
    'build/web',
    defaultDocument: 'index.html',
  );
  final indexHtmlContent = File('build/web/index.html').readAsStringSync();

  final server = await shelf_io.serve(
    (Request request) {
      var requestedPath = request.requestedUri.path.substring(1);
      // print(requestedPath);
      if (!requestedPath.startsWith(proxyPrefix)) {
        return Response.notFound(
          '$requestedPath not found, '
          'only <a href="$proxyPrefix">$proxyPrefix</a> exists.',
          headers: {'Content-Type': 'text/html'},
        );
      }

      var remainingPath = requestedPath.substring(proxyPrefix.length);
      if (indexPages.contains(remainingPath)) {
        // path.relative will always treat `from` as if it's a directory, but
        // for URIs that's not correct. If the request is /foo/bar then `.` is
        // `/foo` and not `/foo/bar`. To handle this, trim the last segment if
        // the request does not end with a slash.
        final relativeBaseHref = requestedPath.endsWith('/')
            ? path.posix.relative(proxyPrefix, from: requestedPath)
            : path.posix
                .relative(proxyPrefix, from: path.posix.dirname(requestedPath));
        final content = indexHtmlContent.replaceAll(
          '<base href="/">',
          '<base href="$relativeBaseHref" />',
        );
        print('Serving request for $requestedPath with '
            'relative base href $relativeBaseHref');
        return Response.ok(content, headers: {'Content-Type': 'text/html'});
      } else {
        return staticHandler(request.change(path: 'proxy/1234/'));
      }
      // For any direct requests to the routes in the app, serve up index.html
      // with the base href rewritten so that it lands in /proxy/1234/.
    },
    InternetAddress.loopbackIPv4, // Allows external connections
    0,
  );

  final url = 'http://${server.address.address}:${server.port}/$proxyPrefix';
  print('App is available at $url');
  await Process.run('start', [url], runInShell: true);
}
