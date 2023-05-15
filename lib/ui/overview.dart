import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../qr_scan.dart';
import '../storage.dart';
import './error_screen.dart';
import './loading_screen.dart';
import './scan_result.dart';
import './show_id.dart';
import './share_own_id.dart';
import './modify_own_id.dart';

class ContactOverview extends StatefulWidget {
  const ContactOverview({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<ContactOverview> createState() => _ContactOverviewState();
}

class _ContactOverviewState extends State<ContactOverview> {
  bool loaded = false;
  DBKeyInfo ownID = createPlaceholderOwnID();
  String? error;
  List<DBKeyInfo> keys = [];

  void scan(BuildContext innerContext, DBKeyInfo? compare) async {
    String title = AppLocalizations.of(context)!.scanContact;
    if (compare != null) {
      title = AppLocalizations.of(context)!.scanContactName(compare.name);
    }
    final data = await scanQRCodeAsync(title, context);
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => ScanResult(data: data, check: compare),
        ),
      );
      _loadData();
    }
  }

  void showID(DBKeyInfo id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => ShowID(
          id: id,
          scan: (BuildContext innerContext) {
            scan(innerContext, id);
          },
        ),
      ),
    ).then((flag) => _loadData());
  }

  void shareOwnID() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => ShareOwnID(
          id: ownID,
        ),
      ),
    ).then((flag) => _loadData());
  }

  void editOwnID() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => ModifyOwnID(ownID: ownID, onSaved: (innerContext) {
          Navigator.of(innerContext).pop();
        }),
      ),
    ).then((flag) => _loadData());
  }

  void _loadData() async {
    try {
      final storage = await getStorage();
      final tmpOwnID = await storage.fetchOwnKeyInfo();
      final dBkeys = await storage.fetchKeyInfos();
      setState(() {
        loaded = true;
        keys = dBkeys;
        if (tmpOwnID != null) {
          ownID = tmpOwnID;
        }
        error = null;
      });
    } catch (e) {
      setState(() {
        loaded = true;
        keys = [];
        error = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    if (!loaded) {
      return loadingScreen(localization.appInit);
    }
    if (error != null) {
      return showError(localization.appInitFailed, error!);
    }
    if (isPlaceholderOwnID(ownID)) {
      return ModifyOwnID(ownID: ownID, onSaved: (context) {
        _loadData();
      });
    }
    final children = ListView.separated(
      separatorBuilder: (context, index) => const Divider(
        height: 1.0,
        thickness: 3.0,
      ),
      // add gap for floatingActionButton
      padding: const EdgeInsets.only(bottom: 60),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final pos = i;
        return ListTile(
          leading: const Icon(Icons.person),
          title: Row(
            children: [
              Text(keys[pos].name),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_outlined),
                iconSize: 30,
                padding: const EdgeInsets.fromLTRB(40, 5, 10, 5),
                tooltip: localization.saveID,
                onPressed: () {
                  scan(context, keys[pos]);
                },
              ),
            ],
          ),
          onTap: () {
            showID(keys[pos]);
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          PopupMenuButton(
            iconSize: 30,
            padding: const EdgeInsets.fromLTRB(40, 8, 10, 8),
            onSelected: (result) {
              if (result == 0) {
                editOwnID();
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 0,
                  child: Text(localization.modifyID),
                ),
              ];
            },
          ),
        ],
      ),
      body: children,
      floatingActionButton: Wrap(
        direction: Axis.horizontal,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 10),
            child: FloatingActionButton.extended(
              heroTag: "scan",
              onPressed: () {
                scan(context, null);
              },
              tooltip: localization.qrScanTooltip,
              label: const Icon(Icons.person_add),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 10),
            child: FloatingActionButton.extended(
              heroTag: "share",
              onPressed: shareOwnID,
              tooltip: localization.shareTooltip,
              label: const Icon(Icons.share),
            ),
          ),
        ],
      ),
    );
  }
}
