abstract class MeshException implements Exception {
  final String message;
  final String? code;
  final String userMessage;

  const MeshException(this.message, {this.code, required this.userMessage});

  @override
  String toString() => 'MeshException [$code]: $message ($userMessage)';
}

class BluetoothDisabledException extends MeshException {
  BluetoothDisabledException()
      : super(
          'Bluetooth adapter is powered off or unavailable',
          code: 'BT_DISABLED',
          userMessage: 'Bluetooth is turned off. Please enable Bluetooth in Settings.',
        );
}

class PermissionDeniedException extends MeshException {
  final String permissionName;
  PermissionDeniedException(this.permissionName)
      : super(
          'Permission denied for $permissionName',
          code: 'PERMISSION_DENIED',
          userMessage: 'Nearby-device or location access is disabled. Please grant permissions in Settings.',
        );
}

class EncryptionException extends MeshException {
  EncryptionException(String details)
      : super(
          'Cryptographic operation failed: $details',
          code: 'CRYPTO_ERROR',
          userMessage: 'Secure message encryption or verification failed.',
        );
}

class MalformedPacketException extends MeshException {
  MalformedPacketException(String details)
      : super(
          'Malformed packet received: $details',
          code: 'MALFORMED_PACKET',
          userMessage: 'Received an invalid or unparseable mesh packet.',
        );
}

class TtlExpiredException extends MeshException {
  final String messageId;
  TtlExpiredException(this.messageId)
      : super(
          'Packet TTL expired for message $messageId',
          code: 'TTL_EXPIRED',
          userMessage: 'Message reached max hops before reaching its destination.',
        );
}

class RouteNotFoundException extends MeshException {
  final String destinationId;
  RouteNotFoundException(this.destinationId)
      : super(
          'No valid route to destination $destinationId',
          code: 'NO_ROUTE',
          userMessage: 'No nearby peers or relays are currently available for this contact.',
        );
}

class PacketDroppedException extends MeshException {
  final String reason;
  PacketDroppedException(this.reason)
      : super(
          'Packet dropped: $reason',
          code: 'PACKET_DROPPED',
          userMessage: 'Message dropped by mesh policy.',
        );
}
