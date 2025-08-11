import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'complaints.dart';
import 'home.dart';

class ComplaintsFullPage extends StatefulWidget {
  const ComplaintsFullPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<ComplaintsFullPage> createState() => _ComplaintsFullPageState();
}

class _ComplaintsFullPageState extends State<ComplaintsFullPage> {
  List<String> cid_ = [];
  List<String> complaint_ = [];
  List<String> date_ = [];
  List<String> replay_ = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Spotify Theme Colors
  final Color primaryColor = const Color(0xFF1DB954); // Spotify Green
  final Color backgroundColor = const Color(0xFF121212);
  final Color cardColor = const Color(0xFF1E1E1E);
  final Color textColor = Colors.white;
  final Color subtitleColor = const Color(0xFFB3B3B3);
  final Color pendingColor = const Color(0xFFFFA726); // Amber for pending
  final Color errorColor = const Color(0xFFE53935); // Red for errors

  // Colorful effects for the table
  final List<Color> rowColors = [
    const Color(0xFF282828),
    const Color(0xFF212121),
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      setState(() {
        _isLoading = !_isRefreshing;
        _isRefreshing = true;
      });

      final pref = await SharedPreferences.getInstance();
      String url = "${pref.getString("url")}user_view_complaint";
      var data = await http.post(Uri.parse(url), body: {
        'lid': pref.getString("lid").toString()
      });

      var jsondata = json.decode(data.body);
      var arr = jsondata["data"];

      setState(() {
        cid_ = List<String>.from(arr.map((e) => e['id'].toString()));
        complaint_ = List<String>.from(arr.map((e) => e['content'].toString()));
        date_ = List<String>.from(arr.map((e) => e['date'].toString()));
        replay_ = List<String>.from(arr.map((e) => e['reply'].toString()));
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      _showErrorSnackbar("Couldn't load complaints. Please try again.");
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final DateTime date = DateTime.parse(dateStr);
      final List<String> months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showReplyDialog(String reply, String date, String complaint) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Complaint Details',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(color: Colors.grey, thickness: 0.2),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder.all(
                      color: subtitleColor.withOpacity(0.2), width: 0.5),
                  children: [
                    _buildTableRow('Date', _formatDate(date), 0),
                    _buildTableRow('Complaint', complaint, 1),
                    _buildTableRow(
                        'Reply', reply.isEmpty ? "Pending" : reply, 0,
                        isPending: reply.isEmpty),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  TableRow _buildTableRow(String title, String content, int rowIndex,
      {bool isPending = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: rowColors[rowIndex % rowColors.length],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            title,
            style: TextStyle(
              color: subtitleColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            content,
            style: TextStyle(
              color: isPending ? pendingColor : textColor,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Homepage()));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: cardColor,
      elevation: 0, // Removed elevation
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      iconTheme: IconThemeData(color: primaryColor),
      actions: [
        IconButton(
          icon: _isRefreshing
              ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 2.5,
            ),
          )
              : Icon(Icons.refresh, color: primaryColor),
          onPressed: _isRefreshing ? null : load,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading complaints...',
              style: TextStyle(color: subtitleColor),
            ),
          ],
        ),
      );
    } else if (cid_.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: subtitleColor.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No complaints found',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to submit a new complaint',
              style: TextStyle(
                color: subtitleColor,
              ),
            ),
          ],
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: load,
        color: primaryColor,
        backgroundColor: cardColor,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cid_.length,
          itemBuilder: (context, index) {
            return _buildComplaintCard(index);
          },
        ),
      );
    }
  }

  Widget _buildComplaintCard(int index) {
    final bool hasReply = replay_[index].isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      elevation: 0, // Removed elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showReplyDialog(
          replay_[index],
          date_[index],
          complaint_[index],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasReply ? Icons.mark_email_read : Icons.mark_email_unread,
                      color: hasReply ? primaryColor : pendingColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint_[index],
                          style: TextStyle(
                            color: textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(date_[index]),
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const complaints()),
        ).then((_) => load());
      },
      icon: const Icon(Icons.add),
      label: const Text(
        'New Complaint',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      elevation: 4, // Reduced elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }
}
