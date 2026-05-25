import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:corexchat/src/global/global.dart';
import 'package:corexchat/src/screens/support/add_support_ticket.dart';
import 'package:corexchat/src/screens/support/models/support_ticket_model.dart';
import 'package:corexchat/src/screens/support/providers/support_ticket_provider.dart';
import 'package:corexchat/src/screens/support/support_chat.dart';

class SupportTicketScreen extends StatefulWidget {
  const SupportTicketScreen({Key? key}) : super(key: key);

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  late SupportTicketProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = SupportTicketProvider();

    // Initialize data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.fetchSupportTickets(refresh: true);
    });

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _provider.dispose();
    super.dispose();
  }

  // Scroll listener for pagination
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });

      _provider.loadMore().then((_) {
        setState(() {
          _isLoadingMore = false;
        });
      });
    }
  }

  // Format date string
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  secondaryColor.withOpacity(0.04),
                  chatownColor.withOpacity(0.04),
                ],
              ),
            ),
          ),
          elevation: 0, // No shadow
          centerTitle: false,
          titleSpacing: 0,
          title: const Text(
            'Support Ticket',
            style: TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.normal,
            ),
          ),
          leading: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(CupertinoIcons.back, color: Colors.black)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  Get.to(() => ChangeNotifierProvider.value(
                        value: _provider,
                        child: const AddTicketScreen(),
                      ))?.then((_) {
                    // Refresh tickets when returning from Add Ticket screen
                    _provider.refreshTickets();
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFADE2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Add ticket',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 0, color: const Color(0xFFE9E9E9)),
          ),
          backgroundColor:
              Colors.transparent, // Important for the gradient to show
        ),
        body: Consumer<SupportTicketProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.tickets.isEmpty) {
              // Show loading indicator only on first load
              return loader(context);
            }

            if (provider.hasError && provider.tickets.isEmpty) {
              // Show error message if there's an error and no data
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // const Icon(Icons.error_outline,
                    //     size: 60, color: Colors.red),
                    // const SizedBox(height: 16),
                    Text(
                      provider.errorMessage,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    // const SizedBox(height: 24),
                    // ElevatedButton(
                    //   onPressed: () => provider.refreshTickets(),
                    //   child: const Text('Retry'),
                    // ),
                  ],
                ),
              );
            }

            if (provider.tickets.isEmpty) {
              // Show empty state when there are no tickets
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // const Icon(
                    //   CupertinoIcons.ticket,
                    //   size: 60,
                    //   color: Colors.grey,
                    // ),
                    // const SizedBox(height: 16),
                    const Text(
                      'No support tickets found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    // ElevatedButton(
                    //   onPressed: () =>
                    //       Get.to(() => ChangeNotifierProvider.value(
                    //             value: _provider,
                    //             child: const AddTicketScreen(),
                    //           ))?.then((_) {
                    //     provider.refreshTickets();
                    //   }),
                    //   child: const Text('Create a Ticket'),
                    // ),
                  ],
                ),
              );
            }

            // Show list of tickets with pull-to-refresh
            return RefreshIndicator(
              onRefresh: provider.refreshTickets,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount:
                    provider.tickets.length + (provider.hasMorePages ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show loading indicator at the bottom when loading more tickets
                  if (index == provider.tickets.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final ticket = provider.tickets[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildTicketCard(ticket),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final lastMessage = ticket.getLastMessage() ?? 'No description available';
    final isOpen = ticket.isOpen();

    void navigateToChat(SupportTicket ticket) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            // Create a new provider instance just for this screen
            create: (context) => SupportTicketProvider(),
            child: SupportTicketChatScreen(ticket: ticket),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Navigate to ticket details screen
        // Get.to(() => TicketDetailsScreen(ticket: ticket));
        print('${ticket.ticketId}');
        navigateToChat(ticket);
      },
      child: Card(
        elevation: 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? const Color(0xFFE2F6D3)
                          : const Color(0xFFFFD7D7),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        color: isOpen ? Colors.green[700] : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                ticket.reportTitle ?? 'No Title',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                lastMessage,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF4B4B4B),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
