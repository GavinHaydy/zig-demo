```text
project-root/
├── build.zig         # Zig 构建配置
├── src/
│   ├── main.zig      # 入口：启动 zap
│   │
│   ├── config/       # 配置相关
│   │   └── config.zig
│   │
│   ├── http/         # HTTP 层（controller）
│   │   ├── router.zig
│   │   └── user_controller.zig
│   │
│   ├── logic/        # 业务逻辑层
│   │   └── user_logic.zig
│   │
│   ├── dao/          # 数据访问层
│   │   └── user_dao.zig
│   │
│   ├── model/        # 数据结构定义
│   │   └── user.zig
│   │
│   ├── middleware/   # 中间件（日志、JWT、CORS 等）
│   │   └── auth.zig
│   │
│   └── util/         # 工具函数
│       └── json.zig
```

## 依赖/Dependent libraries
- [zap version=0.10.6](https://github.com/zigzap/zap)
- [zig-jwt version=1.22.1](https://github.com/deatil/zig-jwt)

## TODO
- redis
- pgsql
- mongo