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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizationProvider = context.watch<LocalizationProvider>();
    final authProvider = context.watch<AuthProvider>();

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
    return FutureBuilder<List<AppUser>>(
      future: auth.searchUsers(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentNic = auth.currentUser?.nic;
        final results = (snapshot.data ?? [])
            .where((user) => user.nic != currentNic)
            .toList();

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
                  backgroundImage: (user.profilePhotoPath ?? '').isNotEmpty
                      ? NetworkImage(user.profilePhotoPath!)
                      : null,
                  child: (user.profilePhotoPath ?? '').isEmpty
                      ? const Icon(Icons.person, color: Colors.blue)
                      : null,
                ),
                title: Text(user.fullName),
                subtitle: Text(
                  '${user.dsAreaName ?? user.districtName ?? ''} • ${user.skillIds.take(2).join(", ")}',
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
      },
    );
  }
}
