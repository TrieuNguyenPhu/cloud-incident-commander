# Cloud Incident Commander

Thiết lập **P0** cho nền tảng xử lý sự cố trên AWS. Frontend Next.js/TypeScript
xuất static, API FastAPI/Mangum, contracts sinh từ đặc tả v1.1, Terraform tách
state và GitHub Actions. P0 chỉ có trang khởi đầu và `GET /healthz`; chưa triển
khai đăng nhập, dữ liệu nghiệp vụ hay tài nguyên AWS.

Vùng AWS mặc định cho triển khai sau P0 là **`us-east-1`** theo ADR-018.
Giá thực tế và quyền truy cập dịch vụ sẽ được xác minh trước khi tạo tài nguyên.

## Chạy tại máy

Cần Node **24.18.0**, npm **11.13.0**, Python **3.12**, uv **0.11.11**.
Kiểm tra IaC cần Terraform **1.15.5**. Phiên bản nằm trong các file version và
lockfile; không cần Docker hoặc AWS credentials để chạy P0.

Tại thư mục gốc, PowerShell:

```powershell
npm ci
uv sync --frozen --all-packages
Copy-Item apps/web/.env.example apps/web/.env.local
Copy-Item services/api/.env.example services/api/.env
```

Chỉ copy env ở lần đầu để giữ cấu hình cá nhân. Với Linux/macOS, dùng `cp` thay
cho `Copy-Item`. Mở hai terminal tại thư mục gốc:

```powershell
npm run dev
```

```powershell
npm run dev:api
```

- Web: <http://127.0.0.1:3000>
- API health: <http://127.0.0.1:8000/healthz>
- API docs của endpoint đã triển khai: <http://127.0.0.1:8000/docs>
- Contract mục tiêu đầy đủ: [OpenAPI v1.1](docs/10_API_OPENAPI.yaml).

Frontend P0 chưa gọi API; `NEXT_PUBLIC_*` là cấu hình public cho các bước P1.
Không đặt secrets trong các biến này. Mọi env cá nhân, state, plan và cache đều
được bỏ qua bởi Git.

## Kiểm tra

```powershell
npm run check
node scripts/check-infra.mjs
npm audit --audit-level=high
uvx --from checkov==3.3.29 checkov --directory infra --framework terraform --compact
```

`npm run check` chạy format, ESLint, TypeScript, Ruff, mypy, kiểm tra lệch contract,
pytest và build static ra `apps/web/out/`. Script IaC chạy fmt/validate và các plan
test với **mock provider**, không gọi AWS hay chạy apply. Nó tải provider đã khóa
phiên bản vào cache cục bộ. Lần cài đầu và các security scan cần Internet.

Khi contract được duyệt thay đổi:

```powershell
npm run contracts:generate
npm run contracts:check
```

CI kiểm tra cả Windows và Linux, dependency vulnerabilities, secrets, IaC; không
deploy từ PR. Lệnh quét bổ sung và bằng chứng P0 nằm trong
[báo cáo thiết lập](docs/P0_SETUP.md).

## Cấu trúc

| Đường dẫn            | Nội dung                                          |
| -------------------- | ------------------------------------------------- |
| `apps/web`           | Next.js static export + Tailwind                  |
| `services/api`       | FastAPI và Lambda handler Mangum                  |
| `packages/contracts` | Pydantic và kiểu TypeScript được sinh tự động     |
| `infra/bootstrap`    | Cấu hình state bucket/budget, mặc định tắt        |
| `infra/environments` | Sáu state độc lập, mọi lab mặc định tắt           |
| `tests`              | Contract, health API, workflow/OIDC checks        |
| `docs`               | Đặc tả v1.1, ADR vùng mới và manifest đã cập nhật |

Đọc [Start here](docs/00_START_HERE.md), [báo cáo P0](docs/P0_SETUP.md) và
[hướng dẫn IaC](infra/README.md) trước khi làm P1. Cấu hình branch protection,
GitHub environment và AWS account còn cần bước thiết lập bên ngoài; báo cáo
phân biệt rõ kết quả tại máy với các gate chưa hoàn tất.
