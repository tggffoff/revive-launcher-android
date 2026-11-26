from pathlib import Path
import re

manifest = Path("android/app/src/main/AndroidManifest.xml")
if not manifest.exists():
    raise SystemExit("AndroidManifest.xml was not generated")

xml = manifest.read_text(encoding="utf-8")
permission = '<uses-permission android:name="android.permission.INTERNET" />'
if permission not in xml:
    xml = xml.replace("<application", f"{permission}\n    <application", 1)

callback = """<intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="revive" android:host="auth" android:path="/callback" />
            </intent-filter>"""
if 'android:scheme="revive"' not in xml:
    xml = re.sub(r"</activity>", f"{callback}\n        </activity>", xml, count=1)

manifest.write_text(xml, encoding="utf-8")
