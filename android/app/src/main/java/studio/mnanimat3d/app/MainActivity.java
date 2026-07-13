package studio.mnanimat3d.app;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Intent;
import android.graphics.Color;
import android.content.res.AssetManager;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Base64;
import android.view.View;
import android.view.WindowManager;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Collections;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public final class MainActivity extends Activity {
    private static final int FILE_CHOOSER_REQUEST = 7401;
    private static final String LOCAL_DOMAIN = "appassets.androidplatform.net";
    private static final String START_URL = "https://" + LOCAL_DOMAIN + "/assets/www/index.html";

    private WebView webView;
    private ValueCallback<Uri[]> fileChooserCallback;
    private DownloadBridge downloadBridge;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.rgb(11, 14, 26));
        getWindow().setNavigationBarColor(Color.rgb(11, 14, 26));
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        webView = new WebView(this);
        webView.setBackgroundColor(Color.rgb(11, 14, 26));
        webView.setLayerType(View.LAYER_TYPE_HARDWARE, null);
        setContentView(webView);

        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        settings.setAllowFileAccess(false);
        settings.setAllowFileAccessFromFileURLs(false);
        settings.setAllowUniversalAccessFromFileURLs(false);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        settings.setMediaPlaybackRequiresUserGesture(false);
        settings.setBuiltInZoomControls(false);
        settings.setDisplayZoomControls(false);
        settings.setCacheMode(WebSettings.LOAD_NO_CACHE);
        settings.setUserAgentString(settings.getUserAgentString() + " MNAnimat3DAndroid/1.0");

        webView.setWebViewClient(new LocalContentClient());

        downloadBridge = new DownloadBridge(this);
        webView.addJavascriptInterface(downloadBridge, "MNAnimat3DAndroid");
        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params) {
                if (fileChooserCallback != null) fileChooserCallback.onReceiveValue(null);
                fileChooserCallback = callback;
                try {
                    Intent picker = params.createIntent();
                    picker.addCategory(Intent.CATEGORY_OPENABLE);
                    startActivityForResult(Intent.createChooser(picker, "Importar modelo 3D"), FILE_CHOOSER_REQUEST);
                    return true;
                } catch (Exception error) {
                    fileChooserCallback = null;
                    Toast.makeText(MainActivity.this, "Nenhum seletor de arquivos disponível.", Toast.LENGTH_LONG).show();
                    return false;
                }
            }
        });

        getOnBackInvokedDispatcher().registerOnBackInvokedCallback(0, () -> {
            if (webView.canGoBack()) webView.goBack();
            else finish();
        });
        webView.loadUrl(START_URL);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != FILE_CHOOSER_REQUEST || fileChooserCallback == null) return;
        Uri[] result = WebChromeClient.FileChooserParams.parseResult(resultCode, data);
        fileChooserCallback.onReceiveValue(result);
        fileChooserCallback = null;
    }

    @Override
    protected void onDestroy() {
        if (fileChooserCallback != null) fileChooserCallback.onReceiveValue(null);
        if (downloadBridge != null) downloadBridge.cancelAll();
        if (webView != null) {
            webView.removeJavascriptInterface("MNAnimat3DAndroid");
            webView.stopLoading();
            webView.destroy();
        }
        super.onDestroy();
    }

    private final class LocalContentClient extends WebViewClient {
        @Override
        public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
            Uri uri = request.getUrl();
            String path = uri.getPath();
            if (!LOCAL_DOMAIN.equals(uri.getHost()) || path == null || !path.startsWith("/assets/")) return null;
            String assetPath = Uri.decode(path.substring("/assets/".length()));
            if (assetPath.contains("..") || assetPath.startsWith("/")) return null;
            try {
                InputStream input = getAssets().open(assetPath, AssetManager.ACCESS_STREAMING);
                return new WebResourceResponse(
                        mimeType(assetPath),
                        textEncoding(assetPath),
                        200,
                        "OK",
                        Collections.singletonMap("Cache-Control", "no-cache"),
                        input
                );
            } catch (IOException error) {
                return null;
            }
        }

        @Override
        public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
            Uri uri = request.getUrl();
            if (LOCAL_DOMAIN.equals(uri.getHost())) return false;
            String scheme = uri.getScheme();
            if ("https".equals(scheme) || "http".equals(scheme)) {
                startActivity(new Intent(Intent.ACTION_VIEW, uri));
                return true;
            }
            return true;
        }

        private String mimeType(String path) {
            String lower = path.toLowerCase();
            if (lower.endsWith(".html")) return "text/html";
            if (lower.endsWith(".js") || lower.endsWith(".mjs")) return "text/javascript";
            if (lower.endsWith(".css")) return "text/css";
            if (lower.endsWith(".json")) return "application/json";
            if (lower.endsWith(".webmanifest")) return "application/manifest+json";
            if (lower.endsWith(".svg")) return "image/svg+xml";
            if (lower.endsWith(".png")) return "image/png";
            if (lower.endsWith(".glb")) return "model/gltf-binary";
            if (lower.endsWith(".gltf")) return "model/gltf+json";
            if (lower.endsWith(".wasm")) return "application/wasm";
            if (lower.endsWith(".txt") || lower.endsWith(".md")) return "text/plain";
            return "application/octet-stream";
        }

        private String textEncoding(String path) {
            String mime = mimeType(path);
            return mime.startsWith("text/") || mime.contains("json") || mime.contains("javascript") || mime.contains("svg") ? "UTF-8" : null;
        }
    }

    private static final class DownloadBridge {
        private final Activity activity;
        private final ContentResolver resolver;
        private final File transferDirectory;
        private final Map<String, Transfer> transfers = new ConcurrentHashMap<>();

        DownloadBridge(Activity activity) {
            this.activity = activity;
            this.resolver = activity.getContentResolver();
            this.transferDirectory = new File(activity.getCacheDir(), "mnanimat3d-exports");
            if (!transferDirectory.exists()) transferDirectory.mkdirs();
        }

        @JavascriptInterface
        public void beginFile(String rawId, String rawName, String rawMime) {
            String id = safeId(rawId);
            cancelFile(id);
            try {
                File file = new File(transferDirectory, id + ".part");
                Transfer transfer = new Transfer(file, safeName(rawName), safeMime(rawMime), new FileOutputStream(file));
                transfers.put(id, transfer);
            } catch (Exception error) {
                notifyUser("Não foi possível iniciar a exportação.");
            }
        }

        @JavascriptInterface
        public void appendFileChunk(String rawId, String encodedChunk) {
            Transfer transfer = transfers.get(safeId(rawId));
            if (transfer == null) return;
            try {
                transfer.stream.write(Base64.decode(encodedChunk, Base64.DEFAULT));
            } catch (Exception error) {
                cancelFile(rawId);
                notifyUser("Falha ao gravar a exportação.");
            }
        }

        @JavascriptInterface
        public void finishFile(String rawId) {
            String id = safeId(rawId);
            Transfer transfer = transfers.remove(id);
            if (transfer == null) return;
            Uri destination = null;
            try {
                transfer.stream.close();
                ContentValues values = new ContentValues();
                values.put(MediaStore.MediaColumns.DISPLAY_NAME, transfer.name);
                values.put(MediaStore.MediaColumns.MIME_TYPE, transfer.mime);
                values.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/MNAnimat3D");
                values.put(MediaStore.MediaColumns.IS_PENDING, 1);
                destination = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);
                if (destination == null) throw new IllegalStateException("Downloads indisponível");
                try (InputStream input = new FileInputStream(transfer.file); OutputStream output = resolver.openOutputStream(destination)) {
                    if (output == null) throw new IllegalStateException("Destino indisponível");
                    byte[] buffer = new byte[256 * 1024];
                    int count;
                    while ((count = input.read(buffer)) != -1) output.write(buffer, 0, count);
                }
                values.clear();
                values.put(MediaStore.MediaColumns.IS_PENDING, 0);
                resolver.update(destination, values, null, null);
                transfer.file.delete();
                notifyUser(transfer.name + " salvo em Downloads/MNAnimat3D.");
            } catch (Exception error) {
                if (destination != null) resolver.delete(destination, null, null);
                transfer.file.delete();
                notifyUser("Não foi possível concluir a exportação.");
            }
        }

        @JavascriptInterface
        public void cancelFile(String rawId) {
            Transfer transfer = transfers.remove(safeId(rawId));
            if (transfer == null) return;
            try { transfer.stream.close(); } catch (Exception ignored) { }
            transfer.file.delete();
        }

        void cancelAll() {
            for (String id : transfers.keySet()) cancelFile(id);
        }

        private void notifyUser(String message) {
            activity.runOnUiThread(() -> Toast.makeText(activity, message, Toast.LENGTH_LONG).show());
        }

        private static String safeId(String value) {
            String clean = value == null ? "transfer" : value.replaceAll("[^A-Za-z0-9._-]", "_");
            return clean.substring(0, Math.min(clean.length(), 96));
        }

        private static String safeName(String value) {
            String clean = value == null ? "mnanimat3d-export.bin" : value.replaceAll("[\\\\/:*?\"<>|]", "_");
            return clean.isBlank() ? "mnanimat3d-export.bin" : clean;
        }

        private static String safeMime(String value) {
            return value == null || value.isBlank() ? "application/octet-stream" : value;
        }

        private static final class Transfer {
            final File file;
            final String name;
            final String mime;
            final FileOutputStream stream;

            Transfer(File file, String name, String mime, FileOutputStream stream) {
                this.file = file;
                this.name = name;
                this.mime = mime;
                this.stream = stream;
            }
        }
    }
}
