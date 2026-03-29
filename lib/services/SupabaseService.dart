// lib/services/SupabaseService.dart
//
// Single source of truth for all Supabase DB operations.
// Handles:
//   1. Upserting user profile into `users` table after auth
//   2. Full CRUD for `emergency_contacts` table (scoped to current user)
//   3. Syncing Supabase contacts → local Hive box on login

import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/EmergencyContact.dart';

class SupabaseService {
  // ── Singleton ──────────────────────────────
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  SupabaseService._();

  static const String _boxName = 'emergency_contacts';

  SupabaseClient get _sb => Supabase.instance.client;

  // ── Current user helpers ───────────────────

  User? get currentUser => _sb.auth.currentUser;
  String? get userId => currentUser?.id;
  bool get isLoggedIn => currentUser != null;

  // ─────────────────────────────────────────────
  //  USER PROFILE
  // ─────────────────────────────────────────────

  /// Called right after signIn or signUp.
  /// Inserts a row in `users` if it doesn't exist yet (upsert by id).
  Future<void> upsertUserProfile({String? fullName, String? phone}) async {
    final uid = userId;
    if (uid == null) throw Exception('upsertUserProfile: no active session.');

    await _sb.from('users').upsert(
      // capital U — matches your table name
      {
        'id': uid,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
      onConflict: 'id',
    );
  }

  /// Fetch user profile row from `users` table.

  // ─────────────────────────────────────────────
  //  EMERGENCY CONTACTS — SUPABASE
  // ─────────────────────────────────────────────

  /// Fetch all emergency contacts for the current user from Supabase.
  Future<List<Map<String, dynamic>>> fetchContactsFromSupabase() async {
    final uid = userId;
    if (uid == null) return [];

    final res = await _sb
        .from('emergency_contacts')
        .select()
        .eq('user_id', uid);

    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Insert a new emergency contact linked to the current user.
  Future<Map<String, dynamic>> addContactToSupabase(
    EmergencyContact contact,
  ) async {
    final uid = userId;
    if (uid == null) throw Exception('addContactToSupabase: not logged in.');

    print('[ADD] Adding contact for user: $uid');
    print('[ADD] Contact: ${contact.name}, ${contact.phone}');

    final res = await _sb
        .from('emergency_contacts')
        .insert({
          'user_id': uid,
          'contact_name': contact.name,
          'contact_number': contact.phone,
          'relation': contact.relation,
        })
        .select()
        .single();

    print('[ADD] Supabase response: $res');
    return res as Map<String, dynamic>;
  }

  /// Update an existing contact by its Supabase row `id`.
  Future<void> updateContactInSupabase(
    String supabaseId,
    EmergencyContact contact,
  ) async {
    await _sb
        .from('emergency_contacts')
        .update({
          'contact_name': contact.name,
          'contact_number': contact.phone,
          'relation': contact.relation,
        })
        .eq('id', supabaseId);
  }

  /// Delete a contact by its Supabase row `id`.
  Future<void> deleteContactFromSupabase(String supabaseId) async {
    await _sb.from('emergency_contacts').delete().eq('id', supabaseId);
  }

  // ─────────────────────────────────────────────
  //  SYNC: Supabase → Hive
  // ─────────────────────────────────────────────

  /// Pulls contacts from Supabase and overwrites the local Hive box.
  /// Call this after every successful login / app start when user is logged in.

  /// Push all local Hive contacts to Supabase (used when user logs in
  /// with existing local contacts that aren't in the DB yet).
  Future<void> syncContactsToHive() async {
    if (!isLoggedIn) return;

    try {
      print('[SYNC] Starting sync for user: $userId');
      final remoteRows = await fetchContactsFromSupabase();
      print('[SYNC] Fetched ${remoteRows.length} contacts from Supabase');
      print('[SYNC] Rows: $remoteRows');

      final box = _openBox();
      await box.clear();
      print('[SYNC] Hive box cleared');

      for (int i = 0; i < remoteRows.length; i++) {
        final row = remoteRows[i];
        final contact = EmergencyContact(
          name: row['contact_name'] ?? '',
          phone: row['contact_number'] ?? '',
          relation: row['relation'] ?? '',
          isPrimary: i == 0,
        )..supabaseId = row['id'] as String?;

        await box.add(contact);
        print('[SYNC] Added contact: ${contact.name} ${contact.phone}');
      }
      print('[SYNC] Sync complete. Box now has ${box.length} contacts');
    } catch (e) {
      print('[SYNC] ERROR: $e');
    }
  }
  // ── Helpers ────────────────────────────────

  Box<EmergencyContact> _openBox() {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<EmergencyContact>(_boxName);
    throw StateError(
      'Hive box "$_boxName" is not open. '
      'Call Hive.openBox before using SupabaseService.',
    );
  }
}
