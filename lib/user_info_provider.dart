import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserInfo {
  final String? firstName;
  final String? surname;
  final String? email;
  final String? country;
  final double? groupSize;
  final DateTime? startDate;

  UserInfo({
    this.firstName,
    this.surname,
    this.email,
    this.country,
    this.groupSize,
    this.startDate,
  });

  UserInfo copyWith({
    String? firstName,
    String? surname,
    String? email,
    String? country,
    double? groupSize,
    DateTime? startDate,
  }) {
    return UserInfo(
      firstName: firstName ?? this.firstName,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      country: country ?? this.country,
      groupSize: groupSize ?? this.groupSize,
      startDate: startDate ?? this.startDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'surname': surname,
      'email': email,
      'country': country,
      'groupSize': groupSize,
      'startDate': startDate?.toIso8601String(),
    };
  }
}

class UserInfoNotifier extends StateNotifier<UserInfo> {
  UserInfoNotifier() : super(UserInfo());

  // Form key for validation
  final formKey = GlobalKey<FormState>();

  // Update methods
  void updateFirstName(String firstName) {
    state = state.copyWith(firstName: firstName);
  }

  void updateSurname(String surname) {
    state = state.copyWith(surname: surname);
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void updateCountry(String country) {
    state = state.copyWith(country: country);
  }

  void updateGroupSize(double groupSize) {
    state = state.copyWith(groupSize: groupSize);
  }

  void updateStartDate(DateTime startDate) {
    state = state.copyWith(startDate: startDate);
  }

  // Validate the form
  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  // Reset all fields
  void resetForm() {
    state = UserInfo();
    formKey.currentState?.reset();
  }
}

// Provider for user information
final userInfoProvider = StateNotifierProvider<UserInfoNotifier, UserInfo>((ref) {
  return UserInfoNotifier();
});
