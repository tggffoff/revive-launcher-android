from pathlib import Path
import xml.etree.ElementTree as ET

path = Path("android/app/src/main/AndroidManifest.xml")
if not path.exists():
    raise SystemExit("AndroidManifest.xml missing; run flutter create first")

ET.register_namespace("android", "http://schemas.android.com/apk/res/android")
android = "{http://schemas.android.com/apk/res/android}"
tree = ET.parse(path)
root = tree.getroot()

permission = "android.permission.INTERNET"
if not any(node.get(android + "name") == permission for node in root.findall("uses-permission")):
    node = ET.Element("uses-permission")
    node.set(android + "name", permission)
    root.insert(0, node)

application = root.find("application")
if application is None:
    raise SystemExit("Android application node missing")
activity = next((node for node in application.findall("activity") if node.get(android + "name", "").endswith("MainActivity")), None)
if activity is None:
    raise SystemExit("MainActivity not found in AndroidManifest.xml")

activity.set(android + "exported", "true")
existing = activity.find("intent-filter")
callback_exists = any(
    data.get(android + "scheme") == "revive" and data.get(android + "host") == "auth"
    for intent in activity.findall("intent-filter")
    for data in intent.findall("data")
)
if not callback_exists:
    intent = ET.SubElement(activity, "intent-filter")
    ET.SubElement(intent, "action").set(android + "name", "android.intent.action.VIEW")
    ET.SubElement(intent, "category").set(android + "name", "android.intent.category.DEFAULT")
    ET.SubElement(intent, "category").set(android + "name", "android.intent.category.BROWSABLE")
    ET.SubElement(intent, "data").set(android + "scheme", "revive")
    intent[-1].set(android + "host", "auth")
    intent[-1].set(android + "path", "/callback")

tree.write(path, encoding="utf-8", xml_declaration=True)
