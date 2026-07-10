# Townling game client — headless Godot HTML5 export, served by nginx.
#
# Stage 1 exports the Godot project to WebAssembly using the godot-ci image
# (headless Godot binary + matching export templates). Stage 2 serves the
# static build. Actual game *development* happens in the Godot editor on the
# host; this image is for the shareable web build (fun-test / CI).

ARG GODOT_VERSION=4.4.1

FROM barichello/godot-ci:${GODOT_VERSION} AS export
ARG GODOT_VERSION
WORKDIR /src

# Make export templates discoverable at the path Godot expects.
RUN mkdir -p ~/.local/share/godot/export_templates/ \
 && if [ -d /root/.local/share/godot/templates ]; then \
        mv /root/.local/share/godot/templates/* ~/.local/share/godot/export_templates/ ; \
    fi

COPY . .

# Import resources once, then export. Fail loudly if the build is missing.
RUN mkdir -p build \
 && (godot --headless --import 2>&1 | tail -n 5 || true) \
 && godot --headless --export-release "Web" build/index.html 2>&1 | tail -n 30 \
 && test -f build/index.html

FROM nginx:1.27-alpine AS serve
COPY --from=export /src/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
