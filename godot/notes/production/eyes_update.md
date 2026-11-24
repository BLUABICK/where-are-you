> Обновление 25 ноября 2026: активные наборы всех пяти персонажей заменены перегенерацией `source_assets/art/characters/quality_v3/`. Ниже описана предыдущая версия. Актуальные сведения: `notes/production/sprite_lab.md`.

# Коррекция глаз

Активные спрайты обоих персонажей обновлены из листов `artem_12_poses_eyes_v2.png` и `alyona_12_poses_eyes_v2.png` в соответствующих папках `assets/sprites/characters/`. Для обоих — 12 поз, общий холст 360×520. Редактирование выполнено встроенным imagegen: согласованы зрачки и направление взгляда, исправлены случайные прищуры. Предыдущие листы сохранены.

Для повторной нарезки: `tools/split_artem.ps1 -CharacterId artem -SheetFile artem_12_poses_eyes_v2.png` или `-CharacterId alyona -SheetFile alyona_12_poses_eyes_v2.png`. Промпты сохранены рядом с листами.
