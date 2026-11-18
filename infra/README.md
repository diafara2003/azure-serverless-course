# Infraestructura (Terraform)

## Dos niveles de recursos

| Nivel | Recursos | Quién lo crea | ¿Se puede borrar y recrear? |
|---|---|---|---|
| **Backend** (state de Terraform) | RG `serverless-rg`, storage `tfstateserverless01`, contenedor `tfstate` | `az` CLI, una sola vez | **No.** Se crea una vez y no se toca. |
| **Infra de la app** | Todo lo declarado en `main.tf` (RG `order-system-dev-rg`, service plan, storage, etc.) | Terraform | Sí, con `terraform destroy` / `terraform apply` las veces que quieras. |

## ¿Por qué el backend se crea con `az` y no con Terraform?

`backend.tf` no crea recursos: le indica a Terraform **dónde guardar su state**, el
archivo con el que Terraform recuerda qué recursos creó y cómo.

`terraform init` se conecta a ese storage como primer paso, antes de leer `main.tf`.
Si el storage no existe, Terraform no arranca. Terraform no puede crear el lugar
donde guarda su propia memoria porque lo necesita para funcionar: es un problema de
**huevo y gallina**. Por eso el backend se crea por fuera (con `az`) antes del primer
`terraform init`.

## Paso 1: crear el backend (solo la primera vez)

```bash
az group create -n serverless-rg -l eastus

az storage account create -n tfstateserverless01 -g serverless-rg -l eastus \
  --sku Standard_LRS --min-tls-version TLS1_2 --allow-blob-public-access false

az storage container create -n tfstate --account-name tfstateserverless01 --auth-mode login
```

- Los nombres deben coincidir con `backend.tf`.
- El nombre del storage account es único en todo Azure. Si está ocupado (por ejemplo,
  porque se acaba de borrar y Azure aún no lo libera), usa otro y actualiza `backend.tf`.
- Si el último comando falla por permisos, `--auth-mode login` requiere el rol
  *Storage Blob Data Contributor*. Usa `--auth-mode key` en su lugar.

## Paso 2: inicializar Terraform

```bash
cd infra
terraform init
```

Si el backend se recreó y `.terraform/` todavía apunta a la configuración anterior,
usa `terraform init -reconfigure`.

## Paso 3: crear o actualizar la infraestructura

```bash
terraform plan
terraform apply
```

## Borrar todo: siempre con Terraform, nunca desde el portal

```bash
terraform destroy
```

`terraform destroy` borra solo la infra de la app, deja el backend intacto y mantiene
el state consistente. Después, un `terraform apply` vuelve a crear todo.

Si se borra desde el portal:
- el state queda desincronizado: dice que existen recursos que ya no están;
- si se borra también `serverless-rg`, se pierde el backend y hay que repetir el Paso 1.

## Requisito de la suscripción: registrar namespaces (una sola vez)

Cada tipo de recurso de Azure pertenece a un namespace (*resource provider*) que debe
estar registrado en la suscripción. Si no lo está, `terraform plan` sale bien pero
`terraform apply` falla con `MissingSubscriptionRegistration`.

| Namespace | Recursos que lo usan |
|---|---|
| `Microsoft.Web` | App Service Plan, Function Apps |
| `Microsoft.Storage` | Storage accounts |
| `Microsoft.OperationalInsights` | Log Analytics Workspace |
| `Microsoft.Insights` | Application Insights |

Para revisar el estado de todos:

```bash
for ns in Microsoft.Web Microsoft.Storage Microsoft.OperationalInsights Microsoft.Insights; do
  printf "%-32s %s\n" $ns "$(az provider show -n $ns --query registrationState -o tsv)"
done
```

Para registrar los que digan `NotRegistered`:

```bash
az provider register --namespace Microsoft.Web --wait
az provider register --namespace Microsoft.Storage --wait
az provider register --namespace Microsoft.OperationalInsights --wait
az provider register --namespace Microsoft.Insights --wait
```

El registro es de la suscripción, no de un recurso: borrar recursos no lo deshace.
Si agregas un tipo de recurso nuevo y aparece `MissingSubscriptionRegistration`,
el mensaje de error indica el namespace: regístralo y agrégalo a esta tabla.
