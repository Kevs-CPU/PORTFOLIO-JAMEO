package com.pkmnapps.nearby_connections;

import android.app.Activity;
import android.util.Log;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.net.Uri;

import androidx.annotation.NonNull;

import com.google.android.gms.nearby.Nearby;
import com.google.android.gms.nearby.connection.AdvertisingOptions;
import com.google.android.gms.nearby.connection.ConnectionInfo;
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback;
import com.google.android.gms.nearby.connection.ConnectionOptions;
import com.google.android.gms.nearby.connection.ConnectionResolution;
import com.google.android.gms.nearby.connection.ConnectionType;
import com.google.android.gms.nearby.connection.ConnectionsStatusCodes;
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo;
import com.google.android.gms.nearby.connection.DiscoveryOptions;
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback;
import com.google.android.gms.nearby.connection.Payload;
import com.google.android.gms.nearby.connection.PayloadCallback;
import com.google.android.gms.nearby.connection.PayloadTransferUpdate;
import com.google.android.gms.nearby.connection.Strategy;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileOutputStream;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.EventChannel;

/**
 * NearbyConnectionsPlugin
 */
public class NearbyConnectionsPlugin
        implements MethodCallHandler, FlutterPlugin, ActivityAware {

    private Activity activity;

    private static final String SERVICE_ID =
            "com.pkmnapps.nearby_connections";

    private static MethodChannel channel;
    private static EventChannel eventChannel;
    private static EventChannel.EventSink eventSink;

    private NearbyConnectionsPlugin(Activity activity) {
        this.activity = activity;
    }

    public NearbyConnectionsPlugin() {
    }

    @Override
    public void onMethodCall(MethodCall call, final Result result) {

        switch (call.method) {

            case "copyFileAndDeleteOriginal":

                Log.d(
                        "nearby_connections",
                        "copyFileAndDeleteOriginal"
                );

                String sourceUri =
                        (String) call.argument("sourceUri");

                String destinationFilepath =
                        (String) call.argument(
                                "destinationFilepath"
                        );

                try {

                    Uri uri = Uri.parse(sourceUri);

                    InputStream in =
                            activity
                                    .getContentResolver()
                                    .openInputStream(uri);

                    copyStream(
                            in,
                            new FileOutputStream(
                                    new File(
                                            destinationFilepath
                                    )
                            )
                    );

                    activity
                            .getContentResolver()
                            .delete(
                                    uri,
                                    null,
                                    null
                            );

                    result.success(true);

                } catch (IOException e) {

                    Log.e(
                            "nearby_connections",
                            e.getMessage()
                    );

                    result.success(false);
                }

                break;

            case "stopAdvertising":

                Log.d(
                        "nearby_connections",
                        "stopAdvertising"
                );

                Nearby
                        .getConnectionsClient(activity)
                        .stopAdvertising();

                result.success(null);

                break;

            case "stopDiscovery":

                Log.d(
                        "nearby_connections",
                        "stopDiscovery"
                );

                Nearby
                        .getConnectionsClient(activity)
                        .stopDiscovery();

                result.success(null);

                break;

            case "startAdvertising": {

                String userNickName =
                        (String) call.argument(
                                "userNickName"
                        );

                int strategy =
                        (int) call.argument("strategy");

                String serviceId =
                        (String) call.argument("serviceId");

                assert userNickName != null;

                if (serviceId == null || serviceId == "")
                    serviceId = SERVICE_ID;

                // =====================================================
                // ACTIVITY 4 - LOCAL MESH CHAT
                //
                // Non-disruptive:
                // Nearby should not intentionally change the current
                // Wi-Fi/Bluetooth state.
                //
                // Low power:
                // Prefer low-power nearby communication such as BLE.
                // =====================================================
                AdvertisingOptions advertisingOptions =
                        new AdvertisingOptions.Builder()
                                .setStrategy(
                                        getStrategy(strategy)
                                )
                                .setConnectionType(
                                        ConnectionType.NON_DISRUPTIVE
                                )
                                .setLowPower(true)
                                .build();

                Nearby
                        .getConnectionsClient(activity)
                        .startAdvertising(
                                userNickName,
                                serviceId,
                                advertConnectionLifecycleCallback,
                                advertisingOptions
                        )
                        .addOnSuccessListener(
                                new OnSuccessListener<Void>() {

                                    @Override
                                    public void onSuccess(
                                            Void aVoid
                                    ) {

                                        Log.d(
                                                "nearby_connections",
                                                "startAdvertising"
                                        );

                                        result.success(true);
                                    }
                                }
                        )
                        .addOnFailureListener(
                                new OnFailureListener() {

                                    @Override
                                    public void onFailure(
                                            @NonNull Exception e
                                    ) {

                                        result.error(
                                                "Failure",
                                                e.getMessage(),
                                                null
                                        );
                                    }
                                }
                        );

                break;
            }

            case "startDiscovery": {

                String userNickName =
                        (String) call.argument(
                                "userNickName"
                        );

                int strategy =
                        (int) call.argument("strategy");

                String serviceId =
                        (String) call.argument("serviceId");

                assert userNickName != null;

                if (serviceId == null || serviceId == "")
                    serviceId = SERVICE_ID;

                // =====================================================
                // ACTIVITY 4 - LOCAL DISCOVERY
                //
                // Low-power discovery is enabled so the discovery
                // phase prefers low-power nearby communication.
                // =====================================================
                DiscoveryOptions discoveryOptions =
                        new DiscoveryOptions.Builder()
                                .setStrategy(
                                        getStrategy(strategy)
                                )
                                .setLowPower(true)
                                .build();

                Nearby
                        .getConnectionsClient(activity)
                        .startDiscovery(
                                serviceId,
                                endpointDiscoveryCallback,
                                discoveryOptions
                        )
                        .addOnSuccessListener(
                                new OnSuccessListener<Void>() {

                                    @Override
                                    public void onSuccess(
                                            Void aVoid
                                    ) {

                                        Log.d(
                                                "nearby_connections",
                                                "startDiscovery"
                                        );

                                        result.success(true);
                                    }
                                }
                        )
                        .addOnFailureListener(
                                new OnFailureListener() {

                                    @Override
                                    public void onFailure(
                                            @NonNull Exception e
                                    ) {

                                        result.error(
                                                "Failure",
                                                e.getMessage(),
                                                null
                                        );
                                    }
                                }
                        );

                break;
            }

            case "stopAllEndpoints":

                Log.d(
                        "nearby_connections",
                        "stopAllEndpoints"
                );

                Nearby
                        .getConnectionsClient(activity)
                        .stopAllEndpoints();

                result.success(null);

                break;

            case "disconnectFromEndpoint": {

                Log.d(
                        "nearby_connections",
                        "disconnectFromEndpoint"
                );

                String endpointId =
                        call.argument("endpointId");

                assert endpointId != null;

                Nearby
                        .getConnectionsClient(activity)
                        .disconnectFromEndpoint(
                                endpointId
                        );

                result.success(null);

                break;
            }

            case "requestConnection": {

                Log.d(
                        "nearby_connections",
                        "requestConnection"
                );

                String userNickName =
                        (String) call.argument(
                                "userNickName"
                        );

                String endpointId =
                        (String) call.argument(
                                "endpointId"
                        );

                assert userNickName != null;
                assert endpointId != null;

                // =====================================================
                // ACTIVITY 4 - CONNECTION
                //
                // Non-disruptive:
                // Do not intentionally modify the current
                // Wi-Fi/Bluetooth state.
                //
                // Low power:
                // Prefer low-power nearby communication.
                // =====================================================
                ConnectionOptions connectionOptions =
                        new ConnectionOptions.Builder()
                                .setConnectionType(
                                        ConnectionType.NON_DISRUPTIVE
                                )
                                .setLowPower(true)
                                .build();

                Nearby
                        .getConnectionsClient(activity)
                        .requestConnection(
                                userNickName,
                                endpointId,
                                discoverConnectionLifecycleCallback,
                                connectionOptions
                        )
                        .addOnSuccessListener(
                                new OnSuccessListener<Void>() {

                                    @Override
                                    public void onSuccess(
                                            Void aVoid
                                    ) {

                                        result.success(true);
                                    }
                                }
                        )
                        .addOnFailureListener(
                                new OnFailureListener() {

                                    @Override
                                    public void onFailure(
                                            @NonNull Exception e
                                    ) {

                                        result.error(
                                                "Failure",
                                                e.getMessage(),
                                                null
                                        );
                                    }
                                }
                        );

                break;
            }

            case "acceptConnection": {

                String endpointId =
                        (String) call.argument(
                                "endpointId"
                        );

                assert endpointId != null;

                Nearby
                        .getConnectionsClient(activity)
                        .acceptConnection(
                                endpointId,
                                payloadCallback
                        )
                        .addOnSuccessListener(
                                new OnSuccessListener<Void>() {

                                    @Override
                                    public void onSuccess(
                                            Void aVoid
                                    ) {

                                        Log.d(
                                                "nearby_connections",
                                                "acceptConnection"
                                        );

                                        result.success(true);
                                    }
                                }
                        )
                        .addOnFailureListener(
                                new OnFailureListener() {

                                    @Override
                                    public void onFailure(
                                            @NonNull Exception e
                                    ) {

                                        result.error(
                                                "Failure",
                                                e.getMessage(),
                                                null
                                        );
                                    }
                                }
                        );

                break;
            }

            case "rejectConnection": {

                String endpointId =
                        (String) call.argument(
                                "endpointId"
                        );

                assert endpointId != null;

                Nearby
                        .getConnectionsClient(activity)
                        .rejectConnection(endpointId)
                        .addOnSuccessListener(
                                new OnSuccessListener<Void>() {

                                    @Override
                                    public void onSuccess(
                                            Void aVoid
                                    ) {

                                        Log.d(
                                                "nearby_connections",
                                                "rejectConnection"
                                        );

                                        result.success(true);
                                    }
                                }
                        )
                        .addOnFailureListener(
                                new OnFailureListener() {

                                    @Override
                                    public void onFailure(
                                            @NonNull Exception e
                                    ) {

                                        result.error(
                                                "Failure",
                                                e.getMessage(),
                                                null
                                        );
                                    }
                                }
                        );

                break;
            }

            case "sendPayload": {

                String endpointId =
                        (String) call.argument(
                                "endpointId"
                        );

                byte[] bytes =
                        call.argument("bytes");

                assert endpointId != null;
                assert bytes != null;

                Nearby
                        .getConnectionsClient(activity)
                        .sendPayload(
                                endpointId,
                                Payload.fromBytes(bytes)
                        );

                Log.d(
                        "nearby_connections",
                        "sentPayload"
                );

                result.success(true);

                break;
            }

            case "sendFilePayload": {

                String endpointId =
                        (String) call.argument(
                                "endpointId"
                        );

                String filePath =
                        (String) call.argument(
                                "filePath"
                        );

                assert endpointId != null;
                assert filePath != null;

                try {

                    File file =
                            new File(filePath);

                    Payload filePayload =
                            Payload.fromFile(file);

                    Nearby
                            .getConnectionsClient(activity)
                            .sendPayload(
                                    endpointId,
                                    filePayload
                            );

                    Log.d(
                            "nearby_connections",
                            "sentFilePayload"
                    );

                    result.success(
                            filePayload.getId()
                    );

                } catch (FileNotFoundException e) {

                    Log.e(
                            "nearby_connections",
                            "File not found",
                            e
                    );

                    result.error(
                            "Failure",
                            e.getMessage(),
                            null
                    );

                    return;
                }

                break;
            }

            case "cancelPayload": {

                String payloadId =
                        (String) call.argument(
                                "payloadId"
                        );

                assert payloadId != null;

                Nearby
                        .getConnectionsClient(activity)
                        .cancelPayload(
                                Long.parseLong(payloadId)
                        );

                Log.d(
                        "nearby_connections",
                        "cancelPayload"
                );

                result.success(null);

                break;
            }

            default:

                result.notImplemented();
        }
    }

    // ============================================================
    // ADVERTISING CALLBACK
    // ============================================================

    private final ConnectionLifecycleCallback
            advertConnectionLifecycleCallback =
            new ConnectionLifecycleCallback() {

        @Override
        public void onConnectionInitiated(
                @NonNull String endpointId,
                @NonNull ConnectionInfo connectionInfo
        ) {

            Log.d(
                    "nearby_connections",
                    "ad.onConnectionInitiated"
            );

            Map<String, Object> args =
                    new HashMap<>();

            args.put(
                    "endpointId",
                    endpointId
            );

            args.put(
                    "endpointName",
                    connectionInfo.getEndpointName()
            );

            args.put(
                    "authenticationToken",
                    connectionInfo.getAuthenticationToken()
            );

            args.put(
                    "isIncomingConnection",
                    connectionInfo.isIncomingConnection()
            );

            args.put(
                    "method",
                    "ad.onConnectionInitiated"
            );

            eventSink.success(args);
        }

        @Override
        public void onConnectionResult(
                @NonNull String endpointId,
                @NonNull ConnectionResolution connectionResolution
        ) {

            Log.d(
                    "nearby_connections",
                    "ad.onConnectionResult"
            );

            Map<String, Object> args =
                    new HashMap<>();

            args.put(
                    "endpointId",
                    endpointId
            );

            int statusCode = -1;

            switch (
                    connectionResolution
                            .getStatus()
                            .getStatusCode()
            ) {

                case ConnectionsStatusCodes.STATUS_OK:

                    statusCode = 0;

                    // Connected successfully.
                    break;

                case ConnectionsStatusCodes
                        .STATUS_CONNECTION_REJECTED:

                    statusCode = 1;

                    // Connection was rejected.
                    break;

                case ConnectionsStatusCodes.STATUS_ERROR:

                    statusCode = 2;

                    // Connection failed.
                    break;

                default:

                    // Unknown status.
                    break;
            }

            args.put(
                    "statusCode",
                    statusCode
            );

            args.put(
                    "method",
                    "ad.onConnectionResult"
            );

            eventSink.success(args);
        }

        @Override
        public void onDisconnected(
                @NonNull String endpointId
        ) {

            Log.d(
                    "nearby_connections",
                    "ad.onDisconnected"
            );

            Map<String, Object> args =
                    new HashMap<>();

            args.put(
                    "endpointId",
                    endpointId
            );

            args.put(
                    "method",
                    "ad.onDisconnected"
            );

            eventSink.success(args);
        }
    };

    // ============================================================
    // DISCOVERY CONNECTION CALLBACK
    // ============================================================

    private final ConnectionLifecycleCallback
            discoverConnectionLifecycleCallback =
            new ConnectionLifecycleCallback() {

        @Override
        public void onConnectionInitiated(
                @NonNull String endpointId,
                @NonNull ConnectionInfo connectionInfo
        ) {

            Log.d(
                    "nearby_connections",
                    "dis.onConnectionInitiated"
            );

            Map<String, Object> args =
                    new HashMap<>();

            args.put(
                    "endpointId",
                    endpointId
            );

            args.put(
                    "endpointName",
                    connectionInfo.getEndpointName()
            );

            args.put(
                    "authenticationToken",
                    connectionInfo.getAuthenticationToken()
            );

            args.put(
                    "isIncomingConnection",
                    connectionInfo.isIncomingConnection()
            );

            args.put(
                    "method",
                    "dis.onConnectionInitiated"
            );

            eventSink.success(args);
        }

        @Override
        public void onConnectionResult(
                @NonNull String endpointId,
                @NonNull ConnectionResolution connectionResolution
        ) {

            Log.d(
                    "nearby_connections",
                    "dis.onConnectionResult"
            );

            Map<String, Object> args =
                    new HashMap<>();

            args.put(
                    "endpointId",
                    endpointId
            );

            int statusCode = -1;

            switch (
                    connectionResolution
                            .getStatus()
                            .getStatusCode()
            ) {

                case ConnectionsStatusCodes.STATUS_OK:

                    statusCode = 0;

                    // Connected successfully.
                    break;

                case ConnectionsStatusCodes
                        .STATUS_CONNECTION_REJECTED:

                    statusCode = 1;

                    // Connection was rejected.
                    break;

                case ConnectionsStatusCodes.STATUS_ERROR:

                    statusCode = 2;

                    // Connection failed.
                    break;

                default:

                    // Unknown status.
                    break;
            }

            args.put(
                    "statusCode",
                    statusCode
            );

            args.put(
                    "method",
                    "dis.onConnectionResult"
            );

            eventSink.success(args);
        }

        @Override
        public void onDisconnected(
                @NonNull String endpointId
        ) {

            Log.d(
                    "nearby_connections",
                    "dis.onDisconnected"
            );

            Map<String, Object> args =
                    new HashMap<>();

            args.put(
                    "endpointId",
                    endpointId
            );

            args.put(
                    "method",
                    "dis.onDisconnected"
            );

            eventSink.success(args);
        }
    };

    // ============================================================
    // PAYLOAD CALLBACK
    // ============================================================

    private final PayloadCallback payloadCallback =
            new PayloadCallback() {

        @Override
        public void onPayloadReceived(
                @NonNull String endpointId,
                @NonNull Payload payload
        ) {

            Log.d(
                    "nearby_connections",
                    "onPayloadReceived"
            );

            Map<String, Object> args =
                    new HashMap<>();

            args.put(
                    "endpointId",
                    endpointId
            );

            args.put(
                    "payloadId",
                    payload.getId()
            );

            args.put(
                    "type",
                    payload.getType()
            );

            if (
                    payload.getType()
                            == Payload.Type.BYTES
            ) {

                byte[] bytes =
                        payload.asBytes();

                assert bytes != null;

                args.put(
                        "bytes",
                        bytes
                );

            } else if (
                    payload.getType()
                            == Payload.Type.FILE
            ) {

                args.put(
                        "uri",
                        payload
                                .asFile()
                                .asUri()
                                .toString()
                );

                if (
                        VERSION.SDK_INT
                                < VERSION_CODES.Q
                ) {

                    args.put(
                            "filePath",
                            payload
                                    .asFile()
                                    .asJavaFile()
                                    .getAbsolutePath()
                    );
                }
            }

            args.put(
                    "method",
                    "onPayloadReceived"
            );

            eventSink.success(args);
        }

        @Override
        public void onPayloadTransferUpdate(
                @NonNull String endpointId,
                @NonNull PayloadTransferUpdate
                        payloadTransferUpdate
        ) {

            Log.d(
                    "nearby_connections",
                    "onPayloadTransferUpdate"
            );

            Map<String, Object> args =
                    new HashMap<>();

            args.put(
                    "endpointId",
                    endpointId
            );

            args.put(
                    "payloadId",
                    payloadTransferUpdate.getPayloadId()
            );

            args.put(
                    "status",
                    payloadTransferUpdate.getStatus()
            );

            args.put(
                    "bytesTransferred",
                    payloadTransferUpdate
                            .getBytesTransferred()
            );

            args.put(
                    "totalBytes",
                    payloadTransferUpdate
                            .getTotalBytes()
            );

            args.put(
                    "method",
                    "onPayloadTransferUpdate"
            );

            eventSink.success(args);
        }
    };

    // ============================================================
    // ENDPOINT DISCOVERY CALLBACK
    // ============================================================

    private final EndpointDiscoveryCallback
            endpointDiscoveryCallback =
            new EndpointDiscoveryCallback() {

        @Override
        public void onEndpointFound(
                @NonNull String endpointId,
                @NonNull DiscoveredEndpointInfo
                        discoveredEndpointInfo
        ) {

            Log.d(
                    "nearby_connections",
                    "onEndpointFound"
            );

            Map<String, Object> args =
                    new HashMap<>();

            args.put(
                    "endpointId",
                    endpointId
            );

            args.put(
                    "endpointName",
                    discoveredEndpointInfo
                            .getEndpointName()
            );

            args.put(
                    "serviceId",
                    discoveredEndpointInfo
                            .getServiceId()
            );

            args.put(
                    "method",
                    "dis.onEndpointFound"
            );

            eventSink.success(args);
        }

        @Override
        public void onEndpointLost(
                @NonNull String endpointId
        ) {

            Log.d(
                    "nearby_connections",
                    "onEndpointLost"
            );

            Map<String, Object> args =
                    new HashMap<>();

            args.put(
                    "endpointId",
                    endpointId
            );

            args.put(
                    "method",
                    "dis.onEndpointLost"
            );

            eventSink.success(args);
        }
    };

    // ============================================================
    // STRATEGY
    // ============================================================

    private Strategy getStrategy(int strategy) {

        switch (strategy) {

            case 0:
                return Strategy.P2P_CLUSTER;

            case 1:
                return Strategy.P2P_STAR;

            case 2:
                return Strategy.P2P_POINT_TO_POINT;

            default:
                return Strategy.P2P_CLUSTER;
        }
    }

    // ============================================================
    // FLUTTER ENGINE
    // ============================================================

    @Override
    public void onAttachedToEngine(
            @NonNull FlutterPluginBinding binding
    ) {

        channel =
                new MethodChannel(
                        binding.getBinaryMessenger(),
                        "nearby_connections"
                );

        channel.setMethodCallHandler(this);

        eventChannel =
                new EventChannel(
                        binding.getBinaryMessenger(),
                        "nearby_connections/events"
                );

        eventChannel.setStreamHandler(
                new EventChannel.StreamHandler() {

                    @Override
                    public void onListen(
                            Object arguments,
                            EventChannel.EventSink events
                    ) {

                        eventSink = events;
                    }

                    @Override
                    public void onCancel(
                            Object arguments
                    ) {

                        eventSink = null;
                    }
                }
        );
    }

    @Override
    public void onDetachedFromEngine(
            @NonNull FlutterPluginBinding binding
    ) {
    }

    // ============================================================
    // ACTIVITY LIFECYCLE
    // ============================================================

    @Override
    public void onAttachedToActivity(
            @NonNull ActivityPluginBinding binding
    ) {

        this.activity =
                binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }

    @Override
    public void onReattachedToActivityForConfigChanges(
            @NonNull ActivityPluginBinding binding
    ) {

        this.activity =
                binding.getActivity();
    }

    // ============================================================
    // FILE COPY
    // ============================================================

    /** Copies a stream from one location to another. */
    private static void copyStream(
            InputStream in,
            OutputStream out
    ) throws IOException {

        try {

            byte[] buffer =
                    new byte[1024];

            int read;

            while (
                    (read = in.read(buffer)) != -1
            ) {

                out.write(
                        buffer,
                        0,
                        read
                );
            }

            out.flush();

        } finally {

            in.close();
            out.close();
        }
    }
}