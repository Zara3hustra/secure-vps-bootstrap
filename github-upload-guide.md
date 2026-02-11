# Инструкция: Загрузка на GitHub

## Шаг 1: Создать репозиторий на GitHub

1. Идём на https://github.com/new
2. Заполняем:
   - **Repository name:** `secure-vps-bootstrap`
   - **Description:** `Fast & secure VPS setup for dev/staging - Claude Code Skill`
   - **Public** ✅ (или Private, как хотите)
   - **НЕ добавляем** README, .gitignore, license (уже есть в наших файлах)
3. **Create repository**

GitHub покажет URL вашего репозитория:
```
https://github.com/ваш-username/secure-vps-bootstrap.git
```

**Скопируйте этот URL!**

---

## Шаг 2: Скачать файлы проекта

У вас уже есть 7 файлов готовых для загрузки:

1. `SKILL.md` - главный файл skill для Claude Code
2. `secure-vps-bootstrap-v0.2.md` - полная документация
3. `bootstrap.sh` - автоматический установщик
4. `security-check.sh` - скрипт проверки
5. `README.md` - описание проекта для GitHub
6. `LICENSE` - MIT лицензия
7. `.gitignore` - игнорируемые файлы

---

## Шаг 3: Локальная настройка

Откройте терминал и выполните:

```bash
# Создайте директорию проекта
mkdir secure-vps-bootstrap
cd secure-vps-bootstrap

# Инициализируйте git
git init
git branch -M main

# Скопируйте все файлы в эту директорию
# (файлы из /mnt/user-data/outputs/)

# Проверьте, что все на месте
ls -la
# Должны увидеть:
# SKILL.md
# secure-vps-bootstrap-v0.2.md
# bootstrap.sh
# security-check.sh
# README.md
# LICENSE
# .gitignore
```

---

## Шаг 4: Первый коммит

```bash
# Добавить все файлы
git add .

# Проверить что добавлено
git status

# Первый коммит
git commit -m "Initial commit: VPS bootstrap skill v0.2"
```

---

## Шаг 5: Подключить GitHub

```bash
# Добавить remote (замените на ваш URL!)
git remote add origin https://github.com/ваш-username/secure-vps-bootstrap.git

# Проверить
git remote -v
```

---

## Шаг 6: Загрузить на GitHub

```bash
# Первый push
git push -u origin main
```

Если GitHub попросит авторизацию:
- **Username:** ваш GitHub username
- **Password:** используйте **Personal Access Token** (не обычный пароль!)

### Как создать Personal Access Token:

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token (classic)
3. Название: `secure-vps-bootstrap`
4. Галочка на **repo** (полный доступ к репозиториям)
5. Generate token
6. **СКОПИРУЙТЕ токен** (покажется только один раз!)
7. Используйте вместо пароля при git push

---

## Шаг 7: Проверка

Откройте в браузере:
```
https://github.com/ваш-username/secure-vps-bootstrap
```

Должны увидеть:
- ✅ Красивый README с описанием
- ✅ Все файлы на месте
- ✅ Зелёные иконки (MIT license)

---

## Шаг 8: Обновить ссылки в файлах

Теперь нужно заменить `yourusername` на ваш реальный username в файлах:

```bash
# В README.md заменить:
https://raw.githubusercontent.com/yourusername/...
# на
https://raw.githubusercontent.com/ваш-username/...

# То же в secure-vps-bootstrap-v0.2.md
```

**Быстрый способ:**

```bash
# Заменить во всех файлах (macOS/Linux)
find . -type f -name "*.md" -exec sed -i '' 's/yourusername/ваш-username/g' {} +

# Linux (без '')
find . -type f -name "*.md" -exec sed -i 's/yourusername/ваш-username/g' {} +

# Или вручную через редактор
```

Затем:
```bash
git add .
git commit -m "Update GitHub username in URLs"
git push
```

---

## Шаг 9: Настроить GitHub Pages (опционально)

Если хотите красивую документацию:

1. GitHub repo → Settings → Pages
2. Source: Deploy from a branch
3. Branch: `main` / `root`
4. Save

Через несколько минут документация будет доступна по адресу:
```
https://ваш-username.github.io/secure-vps-bootstrap/
```

---

## Готово! 🎉

Теперь можно:

### Использовать через curl:
```bash
curl -sSL https://raw.githubusercontent.com/ваш-username/secure-vps-bootstrap/main/bootstrap.sh | bash
```

### Клонировать как Claude Code Skill:
```bash
git clone https://github.com/ваш-username/secure-vps-bootstrap.git
```

### Поделиться:
```
https://github.com/ваш-username/secure-vps-bootstrap
```

---

## Дальнейшие обновления

Когда захотите обновить код:

```bash
cd secure-vps-bootstrap

# Внести изменения в файлы

# Добавить и закоммитить
git add .
git commit -m "Описание изменений"

# Загрузить
git push
```

---

## Альтернатива: GitHub Desktop (GUI)

Если терминал не нравится:

1. Скачайте https://desktop.github.com/
2. File → Add Local Repository → выбрать папку проекта
3. Commit to main
4. Publish repository (выбрать public/private)
5. Готово!

---

## Нужна помощь?

Если что-то не получается - пишите, помогу разобраться на конкретном шаге.
