import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../management/models.dart';
import '../models.dart';
import '../state.dart';
import 'device_avatar.dart';

String _getSubtitle(DeviceInfo info) {
  final serial = info.serial;
  var subtitle = '';
  if (serial != null) {
    subtitle += 'S/N: $serial ';
  }
  subtitle += 'F/W: ${info.version}';
  return subtitle;
}

class DevicePickerDialog extends ConsumerWidget {
  const DevicePickerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(attachedDevicesProvider).toList();
    final currentNode = ref.watch(currentDeviceProvider);
    final data = ref.watch(currentDeviceDataProvider);

    if (currentNode != null) {
      devices.removeWhere((e) => e.path == currentNode.path);
    }

    return SimpleDialog(
      children: [
        currentNode == null
            ? ListTile(
                leading: const DeviceAvatar(
                  child: Icon(Icons.no_cell),
                ),
                title: const Text('No YubiKey'),
                subtitle: Text(Platform.isAndroid
                    ? 'Insert or tap a YubiKey'
                    : (devices.isEmpty
                        ? 'Insert a YubiKey'
                        : 'Insert a YubiKey, or select an item below')),
              )
            : _CurrentDeviceRow(
                currentNode,
                data: data,
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
        if (devices.isNotEmpty) const Divider(),
        ...devices.map(
          (e) => _DeviceRow(
            e,
            info: e.map(
              usbYubiKey: (node) => node.info,
              nfcReader: (_) => null,
            ),
            onTap: () {
              Navigator.of(context).pop();
              ref.read(currentDeviceProvider.notifier).setCurrentDevice(e);
            },
          ),
        ),
      ],
    );
  }
}

class _CurrentDeviceRow extends StatelessWidget {
  final DeviceNode node;
  final YubiKeyData? data;
  final Function() onTap;

  const _CurrentDeviceRow(
    this.node, {
    this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return node.when(usbYubiKey: (path, name, pid, info) {
      if (info != null) {
        return ListTile(
          leading: DeviceAvatar.yubiKeyData(
            data!,
            selected: true,
          ),
          title: Text(name),
          subtitle: Text(_getSubtitle(info)),
          onTap: onTap,
        );
      } else {
        {
          return ListTile(
            leading: DeviceAvatar.deviceNode(
              node,
              selected: true,
            ),
            title: Text(name),
            subtitle: const Text('Device inaccessible'),
            onTap: onTap,
          );
        }
      }
    }, nfcReader: (path, name) {
      final info = data?.info;
      if (info != null) {
        return ListTile(
          leading: DeviceAvatar.yubiKeyData(
            data!,
            selected: true,
          ),
          title: Text(data!.name),
          isThreeLine: true,
          subtitle: Text('$name\n${_getSubtitle(info)}'),
          onTap: onTap,
        );
      } else {
        return ListTile(
          leading: DeviceAvatar.deviceNode(
            node,
            selected: true,
          ),
          title: const Text('No YubiKey present'),
          subtitle: Text(name),
          onTap: onTap,
        );
      }
    });
  }
}

class _DeviceRow extends StatelessWidget {
  final DeviceNode node;
  final DeviceInfo? info;
  final Function() onTap;

  const _DeviceRow(
    this.node, {
    required this.info,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: DeviceAvatar.deviceNode(
          node,
          radius: 20,
        ),
      ),
      title: Text(node.name),
      subtitle: Text(
        node.when(
          usbYubiKey: (_, __, ___, info) =>
              info == null ? 'Device inaccessible' : _getSubtitle(info),
          nfcReader: (_, __) => 'Select to scan',
        ),
      ),
      onTap: onTap,
    );
  }
}
