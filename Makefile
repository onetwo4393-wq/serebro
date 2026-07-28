# Makefile — SerEbro
# Atajos de desarrollo y verificación. Ver scripts/audit-*.sh para el
# detalle de qué chequea cada uno y por qué (nacen de bugs reales
# encontrados en este repo, ver AUDITORIA_SONNET.md).

.PHONY: doctor audit-css audit-darkmode audit-build audit-frontmatter build serve clean help

help:
	@echo "make doctor          - corre los 4 audits (css, dark mode, build, frontmatter) y reporta todo junto"
	@echo "make audit-css       - solo el audit de cascada CSS"
	@echo "make audit-darkmode  - solo el audit de sincronización light/dark"
	@echo "make audit-build     - solo build + smoke test de rutas clave"
	@echo "make audit-frontmatter - solo el audit de tipos/nacionalidad en content/protagonistas"
	@echo "make build           - zola build"
	@echo "make serve           - zola serve --interface 0.0.0.0 --port 1111"
	@echo "make clean           - borra public/"

# "doctor" corre los 4 audits SIEMPRE hasta el final, aunque alguno falle
# a mitad de camino — la idea es ver el diagnóstico completo de una sola
# corrida, no cortar en el primer problema. Sale con código != 0 si al
# menos uno falló.
doctor:
	@echo "== make doctor =="
	@status=0; \
	./scripts/audit-css.sh || status=1; \
	echo ""; \
	./scripts/audit-darkmode.sh || status=1; \
	echo ""; \
	./scripts/audit-build.sh || status=1; \
	echo ""; \
	./scripts/audit-frontmatter.sh || status=1; \
	echo ""; \
	if [ $$status -eq 0 ]; then \
		echo "✓ make doctor: los 4 audits pasaron"; \
	else \
		echo "✗ make doctor: al menos un audit encontró problemas — revisar arriba"; \
	fi; \
	exit $$status

audit-css:
	@./scripts/audit-css.sh

audit-darkmode:
	@./scripts/audit-darkmode.sh

audit-build:
	@./scripts/audit-build.sh

audit-frontmatter:
	@./scripts/audit-frontmatter.sh

build:
	zola build

serve:
	zola serve --interface 0.0.0.0 --port 1111

clean:
	rm -rf public
