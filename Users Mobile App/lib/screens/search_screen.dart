import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import 'candidate_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<AppUser> _allUsers =
      []; // In a real app, this would be fetched from a server

  @override
  void initState() {
    super.initState();
    // Simulate fetching all users for search (excluding current user)
    // In our Hive implementation, we can actually fetch them from the box.
  }

  @override
  Widget build(BuildContext context) {
    final localizationProvider = context.watch<LocalizationProvider>();
    final authProvider = context.watch<AuthProvider>();

    // We'll mock some searchable users since we don't have a 'getAllUsers' method yet
    // Actually, let's just use the current user as a searchable item if we search for them,
    // and maybe the demo user.

    return Scaffold(
      appBar: AppBar(
        title: Text(localizationProvider.translate('searchWorker')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: localizationProvider.translate('searchByNameOrNic'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          Expanded(
            child: _searchQuery.isEmpty
                ? _buildInitialState(localizationProvider)
                : _buildResultsList(authProvider, localizationProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(LocalizationProvider lp) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.blue.shade100),
          const SizedBox(height: 16),
          Text(
            lp.translate('searchByNameOrNic'),
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(AuthProvider auth, LocalizationProvider lp) {
    // For now, let's just search the current user or a demo user to show it works
    // In a real app, AuthProvider would have a 'searchUsers' method.
    final currentUser = auth.currentUser;
    List<AppUser> results = [];

    if (currentUser != null) {
      if (currentUser.fullName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          currentUser.nic.contains(_searchQuery)) {
        results.add(currentUser);
      }
    }

    // Mock additional results
    if ("Nimal Silva".toLowerCase().contains(_searchQuery.toLowerCase())) {
      results.add(
        AppUser(
          nic: '851234567V',
          firstName: 'Nimal',
          lastName: 'Silva',
          phone: '0771234567',
          pin: '1234',
          districtName: 'Colombo',
          dsAreaName: 'Colombo 03',
          jobCategoryIds: ['C01'],
          jobCategoryNames: ['Construction'],
          skillIds: ['S101'],
          skillNames: ['Masonry'],
        ),
      );
    }

    if (results.isEmpty) {
      return Center(child: Text(lp.translate('noJobsFound')));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            title: Text(user.fullName),
            subtitle: Text(
              '${user.districtName} • ${user.skillNames.take(2).join(", ")}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CandidateProfileScreen(user: user),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
