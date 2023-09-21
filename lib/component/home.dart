import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.initialUrl}) : super(key: key);

  final String? initialUrl;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // late PullToRefreshController pullToRefreshController;

  double progress = 0;
  int count = 0;
  String? url;
  String shop_id = "";

  InAppWebViewController? webViewController;

  @override
  void initState() {
    initBranchLinks();
    super.initState();
    // pullToRefreshController = PullToRefreshController(
    //   options: PullToRefreshOptions(
    //     color: Colors.blue,
    //   ),
    //   onRefresh: () async {
    //     if (Platform.isAndroid) {
    //       webViewController?.reload();
    //     } else if (Platform.isIOS) {
    //       webViewController?.loadUrl(
    //         urlRequest: URLRequest(url: await webViewController?.getUrl()),
    //       );
    //     }
    //   },
    // );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    implementation: WebViewImplementation.NATIVE,
                    initialUrlRequest: URLRequest(
                      url: Uri.parse(url!),
                    ),
                    initialOptions: InAppWebViewGroupOptions(
                        ios: IOSInAppWebViewOptions(
                            sharedCookiesEnabled: true,
                            enableViewportScale: false),
                        android: AndroidInAppWebViewOptions(
                          databaseEnabled: true,
                          domStorageEnabled: true,
                          allowContentAccess: true,
                          allowFileAccess: true,
                        ),
                        crossPlatform: InAppWebViewOptions(
                            cacheEnabled: true,
                            javaScriptCanOpenWindowsAutomatically: true,
                            javaScriptEnabled: true,
                            supportZoom: false,
                            allowFileAccessFromFileURLs: true,
                            allowUniversalAccessFromFileURLs: true,
                            useShouldOverrideUrlLoading: true,
                            useOnLoadResource: true,
                            mediaPlaybackRequiresUserGesture: false)),
                    // pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      debugPrint('current $url');
                    },
                    androidOnPermissionRequest:
                        (controller, origin, resources) async {
                      return PermissionRequestResponse(
                        resources: resources,
                        action: PermissionRequestResponseAction.GRANT,
                      );
                    },
                    shouldOverrideUrlLoading:
                        (controller, navigationAction) async {
                      var uri = navigationAction.request.url!;
                      // if (![
                      //   "http",
                      //   "https",
                      //   "file",
                      //   "chrome",
                      //   "data",
                      //   "javascript",
                      //   "about"
                      // ].contains(uri.scheme)) {
                      //   return NavigationActionPolicy.CANCEL;
                      // }
                    },
                    onLoadStop: (controller, url) async {
                      // pullToRefreshController.endRefreshing();

                      // setState(() {
                      //   this.url = url.toString();
                      //   urlController.text = this.url;
                      //   this.count += 1;
                      // });
                    },
                    onLoadError: (controller, url, code, message) {
                      // pullToRefreshController.endRefreshing();
                    },
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        // pullToRefreshController.endRefreshing();
                      }
                      setState(() {
                        this.progress = progress / 100;
                      });
                    },
                    onUpdateVisitedHistory: (controller, url, androidIsReload) {

                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      try {
                        debugPrint(
                            '1 decoded console message ${jsonDecode(consoleMessage.message)}');

                        if (jsonDecode(consoleMessage.message)['type'] == '1') {
                          debugPrint(
                              '2 decoded console message ${jsonDecode(consoleMessage.message)}');
                          if (jsonDecode(consoleMessage.message)['shop_id'] !=
                              " ") {
                            shop_id =
                                jsonDecode(consoleMessage.message)['shop_id'];
                            saveShopId(shop_id);
                            sendToFirebase(shop_id);
                          }
                        }

                        if (jsonDecode(consoleMessage.message)['type'] ==
                            '10') {
                          if (jsonDecode(consoleMessage.message)['shop_id'] !=
                              " ") {
                            shop_id =
                                jsonDecode(consoleMessage.message)['shop_id'];
                            unSubscribeToTopic("shop_admin_${shop_id}");
                            clearShopFromSharePref();
                          }
                        }

                        if (jsonDecode(consoleMessage.message)['type'] == '8') {
                          if (jsonDecode(consoleMessage.message)[
                                      'cache_cleared'] ==
                                  null ||
                              jsonDecode(consoleMessage.message)[
                                      'cache_cleared'] ==
                                  'false') {
                            // this won't get triggered when log is coming from backend and works only from the values of local storage

                            // Fluttertoast.showToast(
                            //     msg: 'cache cleared',
                            //     toastLength: Toast.LENGTH_LONG);
                            webViewController!.removeAllUserScripts();
                            debugPrint('cache cleared');
                            webViewController!.evaluateJavascript(
                                source:
                                    "localStorage.setItem('cache_cleared','true')");
                            webViewController!.reload();
                          } else {
                            // Fluttertoast.showToast(
                            //     msg: 'cache not cleared',
                            //     toastLength: Toast.LENGTH_LONG);
                            debugPrint('cache not cleared');
                          }
                        }
                        // WebViewConsoleOutput webViewConsoleOutput =
                        // WebViewConsoleOutput.fromJson(
                        //     jsonDecode(consoleMessage.message));
                        // _handleOutput(webViewConsoleOutput);
                      } catch (e) {
                        // Fluttertoast.showToast(
                        //     msg: 'Something went wrong',
                        //     toastLength: Toast.LENGTH_LONG,
                        //     timeInSecForIos: 5);
                        debugPrint('error $e');
                      }
                    },
                  ),
                  if (progress < 1.0 && (count == 0))
                    Scaffold(
                      body: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/jlb.png',
                              width: 250,
                              height: 250,
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Material(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                              elevation: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Loading ${(progress * 100).toStringAsFixed(1)} / 100',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void initBranchLinks() async {
    try {
      url = widget.initialUrl;
      FlutterBranchSdk.initSession().listen((data) async {
        debugPrint('Branch data: $data');
        if (data.containsKey("+clicked_branch_link") &&
            data["+clicked_branch_link"] == true) {
          debugPrint('Custom string: ${data['~campaign']} ${data['~channel']}');
          if (data.containsKey('jewellery_id')) {
            debugPrint('jewellery_id ${data['jewellery_id']}');
            var redirectUrl = kReleaseMode
                ? "https://admin.jewellers.live/#/dashboard/mobile_estimation"
                : "https://sipadmin.1ounce.in/#/dashboard/mobile_estimation";
            var jewelleryLink = data['~referring_link'];
            var shopId = data['shop_id'];
            SharedPreferences pref = await SharedPreferences.getInstance();
            var loggedInShopId = pref.getString('shop_id');
            debugPrint('shopId $loggedInShopId');
            if(shopId.toString() == loggedInShopId) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Redirecting..'),
              ));
              debugPrint('same shop id');
              setState(() {
                 url = redirectUrl;
              });
              webViewController!.loadUrl(urlRequest: URLRequest(url: Uri.parse(redirectUrl)));
              await Clipboard.setData(ClipboardData(text: jewelleryLink));
            }
          }
          if (data.containsKey('estimation_id')) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Redirecting..'),
            ));
            debugPrint('estimation_id ${data['estimation_id']}');
            var redirectUrl = kReleaseMode
                ? "https://admin.jewellers.live/#/view_estimation;estimation_id=${data['estimation_id']}"
                : "https://sipadmin.1ounce.in/#/view_estimation;estimation_id=${data['estimation_id']}";
            var jewelleryLink = data['~referring_link'];
            var shopId = data['shop_id'];
            setState(() {
              url = redirectUrl;
            });
            webViewController!.loadUrl(urlRequest: URLRequest(url: Uri.parse(redirectUrl)));
          }
        } else {
          debugPrint('Initial url: ${widget.initialUrl}');
          url = widget.initialUrl;
        }
      }, onError: (error) {
        PlatformException platformException = error as PlatformException;
        debugPrint(
            'InitSession error: ${platformException.code} - ${platformException.message}');
      });
    } catch (e) {
      debugPrint('excep $e');
    }
  }
  saveShopId(String shop_id) async {
    debugPrint('shop_id $shop_id');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('shop_id', shop_id);
    debugPrint('prefs ${prefs.getString('shop_id')}');
  }
  void sendToFirebase(String shop_id) {
    Firebase.initializeApp();

    configureFirebaseMessaging();
    subscribeToTopic("shop_admin_${shop_id}");
  }

  void subscribeToTopic(String topicName) async {
    await FirebaseMessaging.instance.subscribeToTopic(topicName);
  }
  void unSubscribeToTopic(String topicName) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topicName);
  }

  void configureFirebaseMessaging() {
    FirebaseMessaging.instance.requestPermission();
  }

  void clearShopFromSharePref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.remove('shop_id');
  }
}
