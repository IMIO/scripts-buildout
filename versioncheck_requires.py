#!/srv/venv/py3.10.15/bin/python
import argparse
import json
import os
import sys


def invert_dependencies(data):
    inverted = {}

    for package, details in data.items():
        for dependent in details.get("required_by", []):
            if dependent not in inverted:
                inverted[dependent] = {
                    "requires": [],
                    "versions": [],
                }
            inverted[dependent]["requires"].append(package)

        inv_pack = inverted.setdefault(package, {"requires": [], "versions": []})
        inv_pack["versions"] = details.get("versions", [])

    return inverted


def save_as_json(data, filename):
    sorted_data = dict(sorted(data.items()))
    with open(filename, "w") as f:
        json.dump(sorted_data, f, indent=2)


def pypi_link(package, version=""):
    title = package
    if version:
        title = version
    return f"<a href='https://pypi.org/project/{package}/{version}' target='_blank'>{title}</a>"


def save_as_html(data, filename):
    sorted_data = dict(sorted(data.items()))
    with open(filename, "w") as f:
        f.write(
            "<!DOCTYPE html><html><head><title>Python Packages Dependencies</title>"
            "<style type='text/css' media='screen'>"
            "table {"
            "  font-family: sans-serif;"
            "  font-size: 80%;"
            "  background-color: efefef;"
            "}"
            "td {"
            "  border: none;"
            "  padding: 0.5em;"
            "  vertical-align: top;"
            "}"
            "thead th {"
            "  border: none;"
            "  padding: 0.5em;"
            "  background-color: #ddddee;"
            "}"
            ".even {"
            "  background-color: #efefff;"
            "}"
            ".odd {"
            "  background-color: #ffffff;"
            "}"
            ".color-D { color: green; }"
            ".color-A { color: black; }"
            ".color-I { color: gray; }"
            ".color-In { color: orange; }"
            ".color-U { color: darkcyan; }"
            ".color-P { color: blue; }"
            ".color-O { color: magenta; }"
            ".color-X { color: red; }"
            "</style>"
            "</head><body><table border='1'><thead><tr class='odd'><th>Package</th><th>Version</th><th>State</th>"
            "<th>Description</th><th>Requires</th></tr></thead>"
        )

        for i, (package, details) in enumerate(sorted_data.items(), 1):
            row_class = "even" if i % 2 == 0 else "odd"
            if not details["versions"]:
                requires = ", ".join(f"<a href='#{req}'>{req}</a>" for req in sorted(details["requires"]))
                f.write(
                    f"<tr id='{package}' class='{row_class}'><td>{pypi_link(package)}</td><td>N/A</td>"
                    f"<td class='color-{details.get('state', 'A')}'>N/A</td><td>N/A</td><td>{requires}</td></tr>"
                )
            else:
                for j, version in enumerate(details["versions"]):
                    requires = (
                        ", ".join(f"<a href='#{req}'>{req}</a>" for req in sorted(details["requires"]))
                        if j == 0
                        else ""
                    )
                    f.write(
                        f"<tr id='{package}' class='{row_class}'><td>{pypi_link(package) if j == 0 else ''}</td>"
                        f"<td>{pypi_link(package, version['version'])}</td>"
                        f"<td class='color-{version['state']}'>{version['state']}</td><td>{version['description']}</td>"
                        f"<td>{requires}</td></tr>"
                    )

        f.write("</table></body></html>")


def main():
    parser = argparse.ArgumentParser(description="Invert Python package dependencies from JSON to JSON and HTML.")
    parser.add_argument("input_file", help="The input JSON file")
    parser.add_argument(
        "-o", "--output", default="checkversion-d", help="Prefix for output files (default: 'checkversion-d')"
    )

    args = parser.parse_args()

    input_filename = args.input_file

    if not os.path.exists(input_filename):
        print(f"Le fichier {input_filename} n'existe pas.")
        sys.exit(1)

    with open(input_filename, "r") as f:
        data = json.load(f)

    inverted_data = invert_dependencies(data)

    save_as_json(inverted_data, f"{args.output}.json")
    save_as_html(inverted_data, f"{args.output}.html")


if __name__ == "__main__":
    main()
