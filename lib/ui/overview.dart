import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../qr_scan.dart';
import '../storage.dart';
import './error_screen.dart';
import './loading_screen.dart';
import './scan_result.dart';
import './show_id.dart';
import './update_own_id.dart';


class ContactOverview extends StatefulWidget {
  const ContactOverview({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<ContactOverview> createState() => _ContactOverviewState();
}

class _ContactOverviewState extends State<ContactOverview> {
  bool loaded = false;
  bool hasOwnKey = false;
  String? error;
  List<DBKeyInfo> keys = [];

  void scan(BuildContext context, DBKeyInfo? compare) {
    String title = AppLocalizations.of(context)!.scanContact;
    if (compare != null) {
      title = AppLocalizations.of(context)!.scanContactName(compare.name);
    }
    scanQRCode(title, context, (innerContext, result) {
      Navigator.of(innerContext).push(
        MaterialPageRoute(
          builder: (c) => ScanResult(idBytes: result, check: compare),
        ),
      ).then((flag) => _loadData());
    });
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

  void editOwnID() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => UpdateOwnID(onSaved: (innerContext) {
          Navigator.of(innerContext).pop();
        }),
      ),
    );
  }

  void _loadData() async {
    try {
      final storage = await getStorage();
      final ownKey = await storage.fetchOwnKeyInfo();
      final dBkeys = await storage.fetchKeyInfos();
      setState(() {
        loaded = true;
        keys = dBkeys;
        hasOwnKey = (ownKey != null);
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
    if (!hasOwnKey) {
      return UpdateOwnID(onSaved: (context) {
        _loadData();
      });
    }
    final children = ListView.separated(
      separatorBuilder: (context, index) => const Divider(
        height: 1.0,
        thickness: 3.0,
      ),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final pos = i;
        return ListTile(
          title: Row(
            children: [
              Text(localization.showName(keys[pos].name)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_outlined),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          scan(context, null);
        },
        tooltip: localization.qrScanTooltip,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
