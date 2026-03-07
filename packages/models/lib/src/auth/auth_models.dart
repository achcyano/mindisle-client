enum SmsPurpose {
  register,
  resetPassword,
}

String smsPurposeToWire(SmsPurpose purpose) {
  return switch (purpose) {
    SmsPurpose.register => 'REGISTER',
    SmsPurpose.resetPassword => 'RESET_PASSWORD',
  };
}
