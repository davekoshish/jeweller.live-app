import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}




class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // late PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  int count=0;
  final urlController = TextEditingController();
  final GlobalKey webViewKey = GlobalKey();

  String shop_id="";


  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      javaScriptEnabled: true,
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
    ),
  );

  @override
  void  initState() {
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

                    key: webViewKey,
                    initialUrlRequest: URLRequest(
                      url: Uri.parse("https://admin.jewellers.live/"),
                    ),
                    initialOptions: options,

                    // pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                        // webViewController!.removeAllUserScripts();
                        // webViewController!.reload();

                      });
                    },
                    androidOnPermissionRequest: (controller, origin, resources) async {
                      return PermissionRequestResponse(
                        resources: resources,
                        action: PermissionRequestResponseAction.GRANT,
                      );
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      var uri = navigationAction.request.url!;
                      if (!["http", "https", "file", "chrome", "data", "javascript", "about"].contains(uri.scheme)) {
                        return NavigationActionPolicy.CANCEL;
                      }
                    },
                    onLoadStop: (controller, url) async {
                      // pullToRefreshController.endRefreshing();

                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                        this.count+=1;
                      });
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
                        urlController.text = url;

                      });
                    },
                    onUpdateVisitedHistory: (controller, url, androidIsReload) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;

                      });
                    },
                    onConsoleMessage: (controller, consoleMessage) {

                      try {




                        debugPrint(
                            '1 decoded console message ${jsonDecode(consoleMessage.message)}');

                        if(jsonDecode(consoleMessage.message)['type']=='1')
                          {
                            if (jsonDecode(consoleMessage.message)['shop_id']!=" ")
                              {
                                this.shop_id=jsonDecode(consoleMessage.message)['shop_id'];
                                sendToFirebase(this.shop_id);

                              }
                          }

                        if(jsonDecode(consoleMessage.message)['type']=='10')
                        {
                          if (jsonDecode(consoleMessage.message)['shop_id']!=" ")
                          {
                            this.shop_id=jsonDecode(consoleMessage.message)['shop_id'];
                            unSubscribeToTopic("shop_admin_${this.shop_id}");

                          }
                        }






                        if (jsonDecode(consoleMessage.message)['type'] ==
                            '8') {
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

                  if (progress < 1.0 && (count==0))   Scaffold(
                    body: Center(
                      child: Image.asset(
                        'assets/images/jlb.png',
                        width: 250,
                        height: 250,
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

}



void sendToFirebase(String shop_id)
{
  Firebase.initializeApp();

  configureFirebaseMessaging();
  subscribeToTopic("shop_admin_${shop_id}");
}

void subscribeToTopic(String topicName) async{
  await FirebaseMessaging.instance.subscribeToTopic(topicName);
}
void unSubscribeToTopic(String topicName) async {
  await FirebaseMessaging.instance.unsubscribeFromTopic(topicName);
}



void configureFirebaseMessaging() {
  FirebaseMessaging.instance.requestPermission();
}
