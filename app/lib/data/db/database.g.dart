// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $QuestsTable extends Quests with TableInfo<$QuestsTable, QuestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<String> tier = GeneratedColumn<String>(
    'tier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedMinutesMeta = const VerificationMeta(
    'estimatedMinutes',
  );
  @override
  late final GeneratedColumn<int> estimatedMinutes = GeneratedColumn<int>(
    'estimated_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceMeta = const VerificationMeta(
    'recurrence',
  );
  @override
  late final GeneratedColumn<String> recurrence = GeneratedColumn<String>(
    'recurrence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _intentionMeta = const VerificationMeta(
    'intention',
  );
  @override
  late final GeneratedColumn<String> intention = GeneratedColumn<String>(
    'intention',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shareLevelMeta = const VerificationMeta(
    'shareLevel',
  );
  @override
  late final GeneratedColumn<String> shareLevel = GeneratedColumn<String>(
    'share_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('private'),
  );
  static const VerificationMeta _remindAtMeta = const VerificationMeta(
    'remindAt',
  );
  @override
  late final GeneratedColumn<int> remindAt = GeneratedColumn<int>(
    'remind_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    tier,
    title,
    notes,
    category,
    priority,
    status,
    dueAt,
    estimatedMinutes,
    recurrence,
    intention,
    shareLevel,
    remindAt,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quests';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('tier')) {
      context.handle(
        _tierMeta,
        tier.isAcceptableOrUnknown(data['tier']!, _tierMeta),
      );
    } else if (isInserting) {
      context.missing(_tierMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('estimated_minutes')) {
      context.handle(
        _estimatedMinutesMeta,
        estimatedMinutes.isAcceptableOrUnknown(
          data['estimated_minutes']!,
          _estimatedMinutesMeta,
        ),
      );
    }
    if (data.containsKey('recurrence')) {
      context.handle(
        _recurrenceMeta,
        recurrence.isAcceptableOrUnknown(data['recurrence']!, _recurrenceMeta),
      );
    }
    if (data.containsKey('intention')) {
      context.handle(
        _intentionMeta,
        intention.isAcceptableOrUnknown(data['intention']!, _intentionMeta),
      );
    }
    if (data.containsKey('share_level')) {
      context.handle(
        _shareLevelMeta,
        shareLevel.isAcceptableOrUnknown(data['share_level']!, _shareLevelMeta),
      );
    }
    if (data.containsKey('remind_at')) {
      context.handle(
        _remindAtMeta,
        remindAt.isAcceptableOrUnknown(data['remind_at']!, _remindAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      tier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tier'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      estimatedMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_minutes'],
      ),
      recurrence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence'],
      )!,
      intention: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intention'],
      ),
      shareLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}share_level'],
      )!,
      remindAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remind_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $QuestsTable createAlias(String alias) {
    return $QuestsTable(attachedDatabase, alias);
  }
}

class QuestRow extends DataClass implements Insertable<QuestRow> {
  final String id;
  final String? parentId;
  final String tier;
  final String title;
  final String notes;

  /// Category chosen by the user; null lets the evaluator decide.
  final String? category;
  final int priority;

  /// `active`, `completed` or `archived`.
  final String status;
  final DateTime? dueAt;
  final int? estimatedMinutes;

  /// `none`, `daily`, `weekdays` or `weekly`.
  final String recurrence;
  final String? intention;
  final String shareLevel;

  /// Reminder time as minutes after local midnight (schema v2).
  final int? remindAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const QuestRow({
    required this.id,
    this.parentId,
    required this.tier,
    required this.title,
    required this.notes,
    this.category,
    required this.priority,
    required this.status,
    this.dueAt,
    this.estimatedMinutes,
    required this.recurrence,
    this.intention,
    required this.shareLevel,
    this.remindAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['tier'] = Variable<String>(tier);
    map['title'] = Variable<String>(title);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['priority'] = Variable<int>(priority);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    if (!nullToAbsent || estimatedMinutes != null) {
      map['estimated_minutes'] = Variable<int>(estimatedMinutes);
    }
    map['recurrence'] = Variable<String>(recurrence);
    if (!nullToAbsent || intention != null) {
      map['intention'] = Variable<String>(intention);
    }
    map['share_level'] = Variable<String>(shareLevel);
    if (!nullToAbsent || remindAt != null) {
      map['remind_at'] = Variable<int>(remindAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  QuestsCompanion toCompanion(bool nullToAbsent) {
    return QuestsCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      tier: Value(tier),
      title: Value(title),
      notes: Value(notes),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      priority: Value(priority),
      status: Value(status),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      estimatedMinutes: estimatedMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedMinutes),
      recurrence: Value(recurrence),
      intention: intention == null && nullToAbsent
          ? const Value.absent()
          : Value(intention),
      shareLevel: Value(shareLevel),
      remindAt: remindAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remindAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory QuestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestRow(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      tier: serializer.fromJson<String>(json['tier']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String>(json['notes']),
      category: serializer.fromJson<String?>(json['category']),
      priority: serializer.fromJson<int>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      estimatedMinutes: serializer.fromJson<int?>(json['estimatedMinutes']),
      recurrence: serializer.fromJson<String>(json['recurrence']),
      intention: serializer.fromJson<String?>(json['intention']),
      shareLevel: serializer.fromJson<String>(json['shareLevel']),
      remindAt: serializer.fromJson<int?>(json['remindAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'tier': serializer.toJson<String>(tier),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String>(notes),
      'category': serializer.toJson<String?>(category),
      'priority': serializer.toJson<int>(priority),
      'status': serializer.toJson<String>(status),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'estimatedMinutes': serializer.toJson<int?>(estimatedMinutes),
      'recurrence': serializer.toJson<String>(recurrence),
      'intention': serializer.toJson<String?>(intention),
      'shareLevel': serializer.toJson<String>(shareLevel),
      'remindAt': serializer.toJson<int?>(remindAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  QuestRow copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? tier,
    String? title,
    String? notes,
    Value<String?> category = const Value.absent(),
    int? priority,
    String? status,
    Value<DateTime?> dueAt = const Value.absent(),
    Value<int?> estimatedMinutes = const Value.absent(),
    String? recurrence,
    Value<String?> intention = const Value.absent(),
    String? shareLevel,
    Value<int?> remindAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => QuestRow(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    tier: tier ?? this.tier,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    category: category.present ? category.value : this.category,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    estimatedMinutes: estimatedMinutes.present
        ? estimatedMinutes.value
        : this.estimatedMinutes,
    recurrence: recurrence ?? this.recurrence,
    intention: intention.present ? intention.value : this.intention,
    shareLevel: shareLevel ?? this.shareLevel,
    remindAt: remindAt.present ? remindAt.value : this.remindAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  QuestRow copyWithCompanion(QuestsCompanion data) {
    return QuestRow(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      tier: data.tier.present ? data.tier.value : this.tier,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      category: data.category.present ? data.category.value : this.category,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      estimatedMinutes: data.estimatedMinutes.present
          ? data.estimatedMinutes.value
          : this.estimatedMinutes,
      recurrence: data.recurrence.present
          ? data.recurrence.value
          : this.recurrence,
      intention: data.intention.present ? data.intention.value : this.intention,
      shareLevel: data.shareLevel.present
          ? data.shareLevel.value
          : this.shareLevel,
      remindAt: data.remindAt.present ? data.remindAt.value : this.remindAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestRow(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('tier: $tier, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('category: $category, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('dueAt: $dueAt, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('recurrence: $recurrence, ')
          ..write('intention: $intention, ')
          ..write('shareLevel: $shareLevel, ')
          ..write('remindAt: $remindAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentId,
    tier,
    title,
    notes,
    category,
    priority,
    status,
    dueAt,
    estimatedMinutes,
    recurrence,
    intention,
    shareLevel,
    remindAt,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestRow &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.tier == this.tier &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.category == this.category &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.dueAt == this.dueAt &&
          other.estimatedMinutes == this.estimatedMinutes &&
          other.recurrence == this.recurrence &&
          other.intention == this.intention &&
          other.shareLevel == this.shareLevel &&
          other.remindAt == this.remindAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class QuestsCompanion extends UpdateCompanion<QuestRow> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> tier;
  final Value<String> title;
  final Value<String> notes;
  final Value<String?> category;
  final Value<int> priority;
  final Value<String> status;
  final Value<DateTime?> dueAt;
  final Value<int?> estimatedMinutes;
  final Value<String> recurrence;
  final Value<String?> intention;
  final Value<String> shareLevel;
  final Value<int?> remindAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const QuestsCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.tier = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.category = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.intention = const Value.absent(),
    this.shareLevel = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestsCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required String tier,
    required String title,
    this.notes = const Value.absent(),
    this.category = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.intention = const Value.absent(),
    this.shareLevel = const Value.absent(),
    this.remindAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tier = Value(tier),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<QuestRow> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? tier,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<String>? category,
    Expression<int>? priority,
    Expression<String>? status,
    Expression<DateTime>? dueAt,
    Expression<int>? estimatedMinutes,
    Expression<String>? recurrence,
    Expression<String>? intention,
    Expression<String>? shareLevel,
    Expression<int>? remindAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (tier != null) 'tier': tier,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (dueAt != null) 'due_at': dueAt,
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
      if (recurrence != null) 'recurrence': recurrence,
      if (intention != null) 'intention': intention,
      if (shareLevel != null) 'share_level': shareLevel,
      if (remindAt != null) 'remind_at': remindAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestsCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String>? tier,
    Value<String>? title,
    Value<String>? notes,
    Value<String?>? category,
    Value<int>? priority,
    Value<String>? status,
    Value<DateTime?>? dueAt,
    Value<int?>? estimatedMinutes,
    Value<String>? recurrence,
    Value<String?>? intention,
    Value<String>? shareLevel,
    Value<int?>? remindAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return QuestsCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      tier: tier ?? this.tier,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      recurrence: recurrence ?? this.recurrence,
      intention: intention ?? this.intention,
      shareLevel: shareLevel ?? this.shareLevel,
      remindAt: remindAt ?? this.remindAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (tier.present) {
      map['tier'] = Variable<String>(tier.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (estimatedMinutes.present) {
      map['estimated_minutes'] = Variable<int>(estimatedMinutes.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(recurrence.value);
    }
    if (intention.present) {
      map['intention'] = Variable<String>(intention.value);
    }
    if (shareLevel.present) {
      map['share_level'] = Variable<String>(shareLevel.value);
    }
    if (remindAt.present) {
      map['remind_at'] = Variable<int>(remindAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestsCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('tier: $tier, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('category: $category, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('dueAt: $dueAt, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('recurrence: $recurrence, ')
          ..write('intention: $intention, ')
          ..write('shareLevel: $shareLevel, ')
          ..write('remindAt: $remindAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubtasksTable extends Subtasks
    with TableInfo<$SubtasksTable, SubtaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubtasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questIdMeta = const VerificationMeta(
    'questId',
  );
  @override
  late final GeneratedColumn<String> questId = GeneratedColumn<String>(
    'quest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES quests (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    questId,
    title,
    done,
    position,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subtasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubtaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('quest_id')) {
      context.handle(
        _questIdMeta,
        questId.isAcceptableOrUnknown(data['quest_id']!, _questIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubtaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubtaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      questId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quest_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $SubtasksTable createAlias(String alias) {
    return $SubtasksTable(attachedDatabase, alias);
  }
}

class SubtaskRow extends DataClass implements Insertable<SubtaskRow> {
  final String id;
  final String questId;
  final String title;
  final bool done;
  final int position;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const SubtaskRow({
    required this.id,
    required this.questId,
    required this.title,
    required this.done,
    required this.position,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['quest_id'] = Variable<String>(questId);
    map['title'] = Variable<String>(title);
    map['done'] = Variable<bool>(done);
    map['position'] = Variable<int>(position);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SubtasksCompanion toCompanion(bool nullToAbsent) {
    return SubtasksCompanion(
      id: Value(id),
      questId: Value(questId),
      title: Value(title),
      done: Value(done),
      position: Value(position),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SubtaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubtaskRow(
      id: serializer.fromJson<String>(json['id']),
      questId: serializer.fromJson<String>(json['questId']),
      title: serializer.fromJson<String>(json['title']),
      done: serializer.fromJson<bool>(json['done']),
      position: serializer.fromJson<int>(json['position']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'questId': serializer.toJson<String>(questId),
      'title': serializer.toJson<String>(title),
      'done': serializer.toJson<bool>(done),
      'position': serializer.toJson<int>(position),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  SubtaskRow copyWith({
    String? id,
    String? questId,
    String? title,
    bool? done,
    int? position,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => SubtaskRow(
    id: id ?? this.id,
    questId: questId ?? this.questId,
    title: title ?? this.title,
    done: done ?? this.done,
    position: position ?? this.position,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SubtaskRow copyWithCompanion(SubtasksCompanion data) {
    return SubtaskRow(
      id: data.id.present ? data.id.value : this.id,
      questId: data.questId.present ? data.questId.value : this.questId,
      title: data.title.present ? data.title.value : this.title,
      done: data.done.present ? data.done.value : this.done,
      position: data.position.present ? data.position.value : this.position,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubtaskRow(')
          ..write('id: $id, ')
          ..write('questId: $questId, ')
          ..write('title: $title, ')
          ..write('done: $done, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, questId, title, done, position, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubtaskRow &&
          other.id == this.id &&
          other.questId == this.questId &&
          other.title == this.title &&
          other.done == this.done &&
          other.position == this.position &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SubtasksCompanion extends UpdateCompanion<SubtaskRow> {
  final Value<String> id;
  final Value<String> questId;
  final Value<String> title;
  final Value<bool> done;
  final Value<int> position;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SubtasksCompanion({
    this.id = const Value.absent(),
    this.questId = const Value.absent(),
    this.title = const Value.absent(),
    this.done = const Value.absent(),
    this.position = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubtasksCompanion.insert({
    required String id,
    required String questId,
    required String title,
    this.done = const Value.absent(),
    this.position = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       questId = Value(questId),
       title = Value(title),
       updatedAt = Value(updatedAt);
  static Insertable<SubtaskRow> custom({
    Expression<String>? id,
    Expression<String>? questId,
    Expression<String>? title,
    Expression<bool>? done,
    Expression<int>? position,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questId != null) 'quest_id': questId,
      if (title != null) 'title': title,
      if (done != null) 'done': done,
      if (position != null) 'position': position,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubtasksCompanion copyWith({
    Value<String>? id,
    Value<String>? questId,
    Value<String>? title,
    Value<bool>? done,
    Value<int>? position,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SubtasksCompanion(
      id: id ?? this.id,
      questId: questId ?? this.questId,
      title: title ?? this.title,
      done: done ?? this.done,
      position: position ?? this.position,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (questId.present) {
      map['quest_id'] = Variable<String>(questId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubtasksCompanion(')
          ..write('id: $id, ')
          ..write('questId: $questId, ')
          ..write('title: $title, ')
          ..write('done: $done, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompletionsTable extends Completions
    with TableInfo<$CompletionsTable, CompletionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questIdMeta = const VerificationMeta(
    'questId',
  );
  @override
  late final GeneratedColumn<String> questId = GeneratedColumn<String>(
    'quest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES quests (id)',
    ),
  );
  static const VerificationMeta _occurrenceDayMeta = const VerificationMeta(
    'occurrenceDay',
  );
  @override
  late final GeneratedColumn<String> occurrenceDay = GeneratedColumn<String>(
    'occurrence_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDayMeta = const VerificationMeta(
    'localDay',
  );
  @override
  late final GeneratedColumn<String> localDay = GeneratedColumn<String>(
    'local_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _declaredMinutesMeta = const VerificationMeta(
    'declaredMinutes',
  );
  @override
  late final GeneratedColumn<int> declaredMinutes = GeneratedColumn<int>(
    'declared_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackedMinutesMeta = const VerificationMeta(
    'trackedMinutes',
  );
  @override
  late final GeneratedColumn<int> trackedMinutes = GeneratedColumn<int>(
    'tracked_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    questId,
    occurrenceDay,
    localDay,
    completedAt,
    declaredMinutes,
    trackedMinutes,
    state,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompletionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('quest_id')) {
      context.handle(
        _questIdMeta,
        questId.isAcceptableOrUnknown(data['quest_id']!, _questIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questIdMeta);
    }
    if (data.containsKey('occurrence_day')) {
      context.handle(
        _occurrenceDayMeta,
        occurrenceDay.isAcceptableOrUnknown(
          data['occurrence_day']!,
          _occurrenceDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceDayMeta);
    }
    if (data.containsKey('local_day')) {
      context.handle(
        _localDayMeta,
        localDay.isAcceptableOrUnknown(data['local_day']!, _localDayMeta),
      );
    } else if (isInserting) {
      context.missing(_localDayMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('declared_minutes')) {
      context.handle(
        _declaredMinutesMeta,
        declaredMinutes.isAcceptableOrUnknown(
          data['declared_minutes']!,
          _declaredMinutesMeta,
        ),
      );
    }
    if (data.containsKey('tracked_minutes')) {
      context.handle(
        _trackedMinutesMeta,
        trackedMinutes.isAcceptableOrUnknown(
          data['tracked_minutes']!,
          _trackedMinutesMeta,
        ),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompletionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      questId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quest_id'],
      )!,
      occurrenceDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_day'],
      )!,
      localDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_day'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      declaredMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}declared_minutes'],
      ),
      trackedMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tracked_minutes'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CompletionsTable createAlias(String alias) {
    return $CompletionsTable(attachedDatabase, alias);
  }
}

class CompletionRow extends DataClass implements Insertable<CompletionRow> {
  final String id;
  final String questId;

  /// Local day (yyyy-MM-dd) of the occurrence this completion fulfils.
  final String occurrenceDay;
  final String localDay;
  final DateTime completedAt;
  final int? declaredMinutes;
  final int? trackedMinutes;

  /// `active` or `undone`.
  final String state;
  final DateTime createdAt;
  const CompletionRow({
    required this.id,
    required this.questId,
    required this.occurrenceDay,
    required this.localDay,
    required this.completedAt,
    this.declaredMinutes,
    this.trackedMinutes,
    required this.state,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['quest_id'] = Variable<String>(questId);
    map['occurrence_day'] = Variable<String>(occurrenceDay);
    map['local_day'] = Variable<String>(localDay);
    map['completed_at'] = Variable<DateTime>(completedAt);
    if (!nullToAbsent || declaredMinutes != null) {
      map['declared_minutes'] = Variable<int>(declaredMinutes);
    }
    if (!nullToAbsent || trackedMinutes != null) {
      map['tracked_minutes'] = Variable<int>(trackedMinutes);
    }
    map['state'] = Variable<String>(state);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CompletionsCompanion toCompanion(bool nullToAbsent) {
    return CompletionsCompanion(
      id: Value(id),
      questId: Value(questId),
      occurrenceDay: Value(occurrenceDay),
      localDay: Value(localDay),
      completedAt: Value(completedAt),
      declaredMinutes: declaredMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(declaredMinutes),
      trackedMinutes: trackedMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(trackedMinutes),
      state: Value(state),
      createdAt: Value(createdAt),
    );
  }

  factory CompletionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletionRow(
      id: serializer.fromJson<String>(json['id']),
      questId: serializer.fromJson<String>(json['questId']),
      occurrenceDay: serializer.fromJson<String>(json['occurrenceDay']),
      localDay: serializer.fromJson<String>(json['localDay']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      declaredMinutes: serializer.fromJson<int?>(json['declaredMinutes']),
      trackedMinutes: serializer.fromJson<int?>(json['trackedMinutes']),
      state: serializer.fromJson<String>(json['state']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'questId': serializer.toJson<String>(questId),
      'occurrenceDay': serializer.toJson<String>(occurrenceDay),
      'localDay': serializer.toJson<String>(localDay),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'declaredMinutes': serializer.toJson<int?>(declaredMinutes),
      'trackedMinutes': serializer.toJson<int?>(trackedMinutes),
      'state': serializer.toJson<String>(state),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CompletionRow copyWith({
    String? id,
    String? questId,
    String? occurrenceDay,
    String? localDay,
    DateTime? completedAt,
    Value<int?> declaredMinutes = const Value.absent(),
    Value<int?> trackedMinutes = const Value.absent(),
    String? state,
    DateTime? createdAt,
  }) => CompletionRow(
    id: id ?? this.id,
    questId: questId ?? this.questId,
    occurrenceDay: occurrenceDay ?? this.occurrenceDay,
    localDay: localDay ?? this.localDay,
    completedAt: completedAt ?? this.completedAt,
    declaredMinutes: declaredMinutes.present
        ? declaredMinutes.value
        : this.declaredMinutes,
    trackedMinutes: trackedMinutes.present
        ? trackedMinutes.value
        : this.trackedMinutes,
    state: state ?? this.state,
    createdAt: createdAt ?? this.createdAt,
  );
  CompletionRow copyWithCompanion(CompletionsCompanion data) {
    return CompletionRow(
      id: data.id.present ? data.id.value : this.id,
      questId: data.questId.present ? data.questId.value : this.questId,
      occurrenceDay: data.occurrenceDay.present
          ? data.occurrenceDay.value
          : this.occurrenceDay,
      localDay: data.localDay.present ? data.localDay.value : this.localDay,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      declaredMinutes: data.declaredMinutes.present
          ? data.declaredMinutes.value
          : this.declaredMinutes,
      trackedMinutes: data.trackedMinutes.present
          ? data.trackedMinutes.value
          : this.trackedMinutes,
      state: data.state.present ? data.state.value : this.state,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletionRow(')
          ..write('id: $id, ')
          ..write('questId: $questId, ')
          ..write('occurrenceDay: $occurrenceDay, ')
          ..write('localDay: $localDay, ')
          ..write('completedAt: $completedAt, ')
          ..write('declaredMinutes: $declaredMinutes, ')
          ..write('trackedMinutes: $trackedMinutes, ')
          ..write('state: $state, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    questId,
    occurrenceDay,
    localDay,
    completedAt,
    declaredMinutes,
    trackedMinutes,
    state,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletionRow &&
          other.id == this.id &&
          other.questId == this.questId &&
          other.occurrenceDay == this.occurrenceDay &&
          other.localDay == this.localDay &&
          other.completedAt == this.completedAt &&
          other.declaredMinutes == this.declaredMinutes &&
          other.trackedMinutes == this.trackedMinutes &&
          other.state == this.state &&
          other.createdAt == this.createdAt);
}

class CompletionsCompanion extends UpdateCompanion<CompletionRow> {
  final Value<String> id;
  final Value<String> questId;
  final Value<String> occurrenceDay;
  final Value<String> localDay;
  final Value<DateTime> completedAt;
  final Value<int?> declaredMinutes;
  final Value<int?> trackedMinutes;
  final Value<String> state;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CompletionsCompanion({
    this.id = const Value.absent(),
    this.questId = const Value.absent(),
    this.occurrenceDay = const Value.absent(),
    this.localDay = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.declaredMinutes = const Value.absent(),
    this.trackedMinutes = const Value.absent(),
    this.state = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompletionsCompanion.insert({
    required String id,
    required String questId,
    required String occurrenceDay,
    required String localDay,
    required DateTime completedAt,
    this.declaredMinutes = const Value.absent(),
    this.trackedMinutes = const Value.absent(),
    this.state = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       questId = Value(questId),
       occurrenceDay = Value(occurrenceDay),
       localDay = Value(localDay),
       completedAt = Value(completedAt),
       createdAt = Value(createdAt);
  static Insertable<CompletionRow> custom({
    Expression<String>? id,
    Expression<String>? questId,
    Expression<String>? occurrenceDay,
    Expression<String>? localDay,
    Expression<DateTime>? completedAt,
    Expression<int>? declaredMinutes,
    Expression<int>? trackedMinutes,
    Expression<String>? state,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questId != null) 'quest_id': questId,
      if (occurrenceDay != null) 'occurrence_day': occurrenceDay,
      if (localDay != null) 'local_day': localDay,
      if (completedAt != null) 'completed_at': completedAt,
      if (declaredMinutes != null) 'declared_minutes': declaredMinutes,
      if (trackedMinutes != null) 'tracked_minutes': trackedMinutes,
      if (state != null) 'state': state,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompletionsCompanion copyWith({
    Value<String>? id,
    Value<String>? questId,
    Value<String>? occurrenceDay,
    Value<String>? localDay,
    Value<DateTime>? completedAt,
    Value<int?>? declaredMinutes,
    Value<int?>? trackedMinutes,
    Value<String>? state,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CompletionsCompanion(
      id: id ?? this.id,
      questId: questId ?? this.questId,
      occurrenceDay: occurrenceDay ?? this.occurrenceDay,
      localDay: localDay ?? this.localDay,
      completedAt: completedAt ?? this.completedAt,
      declaredMinutes: declaredMinutes ?? this.declaredMinutes,
      trackedMinutes: trackedMinutes ?? this.trackedMinutes,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (questId.present) {
      map['quest_id'] = Variable<String>(questId.value);
    }
    if (occurrenceDay.present) {
      map['occurrence_day'] = Variable<String>(occurrenceDay.value);
    }
    if (localDay.present) {
      map['local_day'] = Variable<String>(localDay.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (declaredMinutes.present) {
      map['declared_minutes'] = Variable<int>(declaredMinutes.value);
    }
    if (trackedMinutes.present) {
      map['tracked_minutes'] = Variable<int>(trackedMinutes.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletionsCompanion(')
          ..write('id: $id, ')
          ..write('questId: $questId, ')
          ..write('occurrenceDay: $occurrenceDay, ')
          ..write('localDay: $localDay, ')
          ..write('completedAt: $completedAt, ')
          ..write('declaredMinutes: $declaredMinutes, ')
          ..write('trackedMinutes: $trackedMinutes, ')
          ..write('state: $state, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EvaluationsTable extends Evaluations
    with TableInfo<$EvaluationsTable, EvaluationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EvaluationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _completionIdMeta = const VerificationMeta(
    'completionId',
  );
  @override
  late final GeneratedColumn<String> completionId = GeneratedColumn<String>(
    'completion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES completions (id)',
    ),
  );
  static const VerificationMeta _localDayMeta = const VerificationMeta(
    'localDay',
  );
  @override
  late final GeneratedColumn<String> localDay = GeneratedColumn<String>(
    'local_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _similarityKeyMeta = const VerificationMeta(
    'similarityKey',
  );
  @override
  late final GeneratedColumn<String> similarityKey = GeneratedColumn<String>(
    'similarity_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effectiveMinutesMeta = const VerificationMeta(
    'effectiveMinutes',
  );
  @override
  late final GeneratedColumn<int> effectiveMinutes = GeneratedColumn<int>(
    'effective_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalXpMeta = const VerificationMeta(
    'totalXp',
  );
  @override
  late final GeneratedColumn<int> totalXp = GeneratedColumn<int>(
    'total_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trivialMeta = const VerificationMeta(
    'trivial',
  );
  @override
  late final GeneratedColumn<bool> trivial = GeneratedColumn<bool>(
    'trivial',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("trivial" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proposalJsonMeta = const VerificationMeta(
    'proposalJson',
  );
  @override
  late final GeneratedColumn<String> proposalJson = GeneratedColumn<String>(
    'proposal_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultJsonMeta = const VerificationMeta(
    'resultJson',
  );
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
    'result_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _provisionalMeta = const VerificationMeta(
    'provisional',
  );
  @override
  late final GeneratedColumn<bool> provisional = GeneratedColumn<bool>(
    'provisional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("provisional" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    completionId,
    localDay,
    category,
    similarityKey,
    effectiveMinutes,
    totalXp,
    trivial,
    source,
    proposalJson,
    resultJson,
    provisional,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'evaluations';
  @override
  VerificationContext validateIntegrity(
    Insertable<EvaluationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('completion_id')) {
      context.handle(
        _completionIdMeta,
        completionId.isAcceptableOrUnknown(
          data['completion_id']!,
          _completionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completionIdMeta);
    }
    if (data.containsKey('local_day')) {
      context.handle(
        _localDayMeta,
        localDay.isAcceptableOrUnknown(data['local_day']!, _localDayMeta),
      );
    } else if (isInserting) {
      context.missing(_localDayMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('similarity_key')) {
      context.handle(
        _similarityKeyMeta,
        similarityKey.isAcceptableOrUnknown(
          data['similarity_key']!,
          _similarityKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_similarityKeyMeta);
    }
    if (data.containsKey('effective_minutes')) {
      context.handle(
        _effectiveMinutesMeta,
        effectiveMinutes.isAcceptableOrUnknown(
          data['effective_minutes']!,
          _effectiveMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveMinutesMeta);
    }
    if (data.containsKey('total_xp')) {
      context.handle(
        _totalXpMeta,
        totalXp.isAcceptableOrUnknown(data['total_xp']!, _totalXpMeta),
      );
    } else if (isInserting) {
      context.missing(_totalXpMeta);
    }
    if (data.containsKey('trivial')) {
      context.handle(
        _trivialMeta,
        trivial.isAcceptableOrUnknown(data['trivial']!, _trivialMeta),
      );
    } else if (isInserting) {
      context.missing(_trivialMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('proposal_json')) {
      context.handle(
        _proposalJsonMeta,
        proposalJson.isAcceptableOrUnknown(
          data['proposal_json']!,
          _proposalJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proposalJsonMeta);
    }
    if (data.containsKey('result_json')) {
      context.handle(
        _resultJsonMeta,
        resultJson.isAcceptableOrUnknown(data['result_json']!, _resultJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_resultJsonMeta);
    }
    if (data.containsKey('provisional')) {
      context.handle(
        _provisionalMeta,
        provisional.isAcceptableOrUnknown(
          data['provisional']!,
          _provisionalMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {completionId};
  @override
  EvaluationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EvaluationRow(
      completionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completion_id'],
      )!,
      localDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_day'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      similarityKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}similarity_key'],
      )!,
      effectiveMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}effective_minutes'],
      )!,
      totalXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_xp'],
      )!,
      trivial: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}trivial'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      proposalJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proposal_json'],
      )!,
      resultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_json'],
      )!,
      provisional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}provisional'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EvaluationsTable createAlias(String alias) {
    return $EvaluationsTable(attachedDatabase, alias);
  }
}

class EvaluationRow extends DataClass implements Insertable<EvaluationRow> {
  final String completionId;
  final String localDay;
  final String category;
  final String similarityKey;
  final int effectiveMinutes;
  final int totalXp;
  final bool trivial;
  final String source;
  final String proposalJson;
  final String resultJson;

  /// True until the server confirms (signed-in users only).
  final bool provisional;
  final DateTime createdAt;
  const EvaluationRow({
    required this.completionId,
    required this.localDay,
    required this.category,
    required this.similarityKey,
    required this.effectiveMinutes,
    required this.totalXp,
    required this.trivial,
    required this.source,
    required this.proposalJson,
    required this.resultJson,
    required this.provisional,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['completion_id'] = Variable<String>(completionId);
    map['local_day'] = Variable<String>(localDay);
    map['category'] = Variable<String>(category);
    map['similarity_key'] = Variable<String>(similarityKey);
    map['effective_minutes'] = Variable<int>(effectiveMinutes);
    map['total_xp'] = Variable<int>(totalXp);
    map['trivial'] = Variable<bool>(trivial);
    map['source'] = Variable<String>(source);
    map['proposal_json'] = Variable<String>(proposalJson);
    map['result_json'] = Variable<String>(resultJson);
    map['provisional'] = Variable<bool>(provisional);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EvaluationsCompanion toCompanion(bool nullToAbsent) {
    return EvaluationsCompanion(
      completionId: Value(completionId),
      localDay: Value(localDay),
      category: Value(category),
      similarityKey: Value(similarityKey),
      effectiveMinutes: Value(effectiveMinutes),
      totalXp: Value(totalXp),
      trivial: Value(trivial),
      source: Value(source),
      proposalJson: Value(proposalJson),
      resultJson: Value(resultJson),
      provisional: Value(provisional),
      createdAt: Value(createdAt),
    );
  }

  factory EvaluationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EvaluationRow(
      completionId: serializer.fromJson<String>(json['completionId']),
      localDay: serializer.fromJson<String>(json['localDay']),
      category: serializer.fromJson<String>(json['category']),
      similarityKey: serializer.fromJson<String>(json['similarityKey']),
      effectiveMinutes: serializer.fromJson<int>(json['effectiveMinutes']),
      totalXp: serializer.fromJson<int>(json['totalXp']),
      trivial: serializer.fromJson<bool>(json['trivial']),
      source: serializer.fromJson<String>(json['source']),
      proposalJson: serializer.fromJson<String>(json['proposalJson']),
      resultJson: serializer.fromJson<String>(json['resultJson']),
      provisional: serializer.fromJson<bool>(json['provisional']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'completionId': serializer.toJson<String>(completionId),
      'localDay': serializer.toJson<String>(localDay),
      'category': serializer.toJson<String>(category),
      'similarityKey': serializer.toJson<String>(similarityKey),
      'effectiveMinutes': serializer.toJson<int>(effectiveMinutes),
      'totalXp': serializer.toJson<int>(totalXp),
      'trivial': serializer.toJson<bool>(trivial),
      'source': serializer.toJson<String>(source),
      'proposalJson': serializer.toJson<String>(proposalJson),
      'resultJson': serializer.toJson<String>(resultJson),
      'provisional': serializer.toJson<bool>(provisional),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EvaluationRow copyWith({
    String? completionId,
    String? localDay,
    String? category,
    String? similarityKey,
    int? effectiveMinutes,
    int? totalXp,
    bool? trivial,
    String? source,
    String? proposalJson,
    String? resultJson,
    bool? provisional,
    DateTime? createdAt,
  }) => EvaluationRow(
    completionId: completionId ?? this.completionId,
    localDay: localDay ?? this.localDay,
    category: category ?? this.category,
    similarityKey: similarityKey ?? this.similarityKey,
    effectiveMinutes: effectiveMinutes ?? this.effectiveMinutes,
    totalXp: totalXp ?? this.totalXp,
    trivial: trivial ?? this.trivial,
    source: source ?? this.source,
    proposalJson: proposalJson ?? this.proposalJson,
    resultJson: resultJson ?? this.resultJson,
    provisional: provisional ?? this.provisional,
    createdAt: createdAt ?? this.createdAt,
  );
  EvaluationRow copyWithCompanion(EvaluationsCompanion data) {
    return EvaluationRow(
      completionId: data.completionId.present
          ? data.completionId.value
          : this.completionId,
      localDay: data.localDay.present ? data.localDay.value : this.localDay,
      category: data.category.present ? data.category.value : this.category,
      similarityKey: data.similarityKey.present
          ? data.similarityKey.value
          : this.similarityKey,
      effectiveMinutes: data.effectiveMinutes.present
          ? data.effectiveMinutes.value
          : this.effectiveMinutes,
      totalXp: data.totalXp.present ? data.totalXp.value : this.totalXp,
      trivial: data.trivial.present ? data.trivial.value : this.trivial,
      source: data.source.present ? data.source.value : this.source,
      proposalJson: data.proposalJson.present
          ? data.proposalJson.value
          : this.proposalJson,
      resultJson: data.resultJson.present
          ? data.resultJson.value
          : this.resultJson,
      provisional: data.provisional.present
          ? data.provisional.value
          : this.provisional,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EvaluationRow(')
          ..write('completionId: $completionId, ')
          ..write('localDay: $localDay, ')
          ..write('category: $category, ')
          ..write('similarityKey: $similarityKey, ')
          ..write('effectiveMinutes: $effectiveMinutes, ')
          ..write('totalXp: $totalXp, ')
          ..write('trivial: $trivial, ')
          ..write('source: $source, ')
          ..write('proposalJson: $proposalJson, ')
          ..write('resultJson: $resultJson, ')
          ..write('provisional: $provisional, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    completionId,
    localDay,
    category,
    similarityKey,
    effectiveMinutes,
    totalXp,
    trivial,
    source,
    proposalJson,
    resultJson,
    provisional,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EvaluationRow &&
          other.completionId == this.completionId &&
          other.localDay == this.localDay &&
          other.category == this.category &&
          other.similarityKey == this.similarityKey &&
          other.effectiveMinutes == this.effectiveMinutes &&
          other.totalXp == this.totalXp &&
          other.trivial == this.trivial &&
          other.source == this.source &&
          other.proposalJson == this.proposalJson &&
          other.resultJson == this.resultJson &&
          other.provisional == this.provisional &&
          other.createdAt == this.createdAt);
}

class EvaluationsCompanion extends UpdateCompanion<EvaluationRow> {
  final Value<String> completionId;
  final Value<String> localDay;
  final Value<String> category;
  final Value<String> similarityKey;
  final Value<int> effectiveMinutes;
  final Value<int> totalXp;
  final Value<bool> trivial;
  final Value<String> source;
  final Value<String> proposalJson;
  final Value<String> resultJson;
  final Value<bool> provisional;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EvaluationsCompanion({
    this.completionId = const Value.absent(),
    this.localDay = const Value.absent(),
    this.category = const Value.absent(),
    this.similarityKey = const Value.absent(),
    this.effectiveMinutes = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.trivial = const Value.absent(),
    this.source = const Value.absent(),
    this.proposalJson = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.provisional = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EvaluationsCompanion.insert({
    required String completionId,
    required String localDay,
    required String category,
    required String similarityKey,
    required int effectiveMinutes,
    required int totalXp,
    required bool trivial,
    required String source,
    required String proposalJson,
    required String resultJson,
    this.provisional = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : completionId = Value(completionId),
       localDay = Value(localDay),
       category = Value(category),
       similarityKey = Value(similarityKey),
       effectiveMinutes = Value(effectiveMinutes),
       totalXp = Value(totalXp),
       trivial = Value(trivial),
       source = Value(source),
       proposalJson = Value(proposalJson),
       resultJson = Value(resultJson),
       createdAt = Value(createdAt);
  static Insertable<EvaluationRow> custom({
    Expression<String>? completionId,
    Expression<String>? localDay,
    Expression<String>? category,
    Expression<String>? similarityKey,
    Expression<int>? effectiveMinutes,
    Expression<int>? totalXp,
    Expression<bool>? trivial,
    Expression<String>? source,
    Expression<String>? proposalJson,
    Expression<String>? resultJson,
    Expression<bool>? provisional,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (completionId != null) 'completion_id': completionId,
      if (localDay != null) 'local_day': localDay,
      if (category != null) 'category': category,
      if (similarityKey != null) 'similarity_key': similarityKey,
      if (effectiveMinutes != null) 'effective_minutes': effectiveMinutes,
      if (totalXp != null) 'total_xp': totalXp,
      if (trivial != null) 'trivial': trivial,
      if (source != null) 'source': source,
      if (proposalJson != null) 'proposal_json': proposalJson,
      if (resultJson != null) 'result_json': resultJson,
      if (provisional != null) 'provisional': provisional,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EvaluationsCompanion copyWith({
    Value<String>? completionId,
    Value<String>? localDay,
    Value<String>? category,
    Value<String>? similarityKey,
    Value<int>? effectiveMinutes,
    Value<int>? totalXp,
    Value<bool>? trivial,
    Value<String>? source,
    Value<String>? proposalJson,
    Value<String>? resultJson,
    Value<bool>? provisional,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return EvaluationsCompanion(
      completionId: completionId ?? this.completionId,
      localDay: localDay ?? this.localDay,
      category: category ?? this.category,
      similarityKey: similarityKey ?? this.similarityKey,
      effectiveMinutes: effectiveMinutes ?? this.effectiveMinutes,
      totalXp: totalXp ?? this.totalXp,
      trivial: trivial ?? this.trivial,
      source: source ?? this.source,
      proposalJson: proposalJson ?? this.proposalJson,
      resultJson: resultJson ?? this.resultJson,
      provisional: provisional ?? this.provisional,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (completionId.present) {
      map['completion_id'] = Variable<String>(completionId.value);
    }
    if (localDay.present) {
      map['local_day'] = Variable<String>(localDay.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (similarityKey.present) {
      map['similarity_key'] = Variable<String>(similarityKey.value);
    }
    if (effectiveMinutes.present) {
      map['effective_minutes'] = Variable<int>(effectiveMinutes.value);
    }
    if (totalXp.present) {
      map['total_xp'] = Variable<int>(totalXp.value);
    }
    if (trivial.present) {
      map['trivial'] = Variable<bool>(trivial.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (proposalJson.present) {
      map['proposal_json'] = Variable<String>(proposalJson.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (provisional.present) {
      map['provisional'] = Variable<bool>(provisional.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EvaluationsCompanion(')
          ..write('completionId: $completionId, ')
          ..write('localDay: $localDay, ')
          ..write('category: $category, ')
          ..write('similarityKey: $similarityKey, ')
          ..write('effectiveMinutes: $effectiveMinutes, ')
          ..write('totalXp: $totalXp, ')
          ..write('trivial: $trivial, ')
          ..write('source: $source, ')
          ..write('proposalJson: $proposalJson, ')
          ..write('resultJson: $resultJson, ')
          ..write('provisional: $provisional, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerEntriesTable extends LedgerEntries
    with TableInfo<$LedgerEntriesTable, LedgerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completionIdMeta = const VerificationMeta(
    'completionId',
  );
  @override
  late final GeneratedColumn<String> completionId = GeneratedColumn<String>(
    'completion_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attributeMeta = const VerificationMeta(
    'attribute',
  );
  @override
  late final GeneratedColumn<String> attribute = GeneratedColumn<String>(
    'attribute',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawAmountMeta = const VerificationMeta(
    'rawAmount',
  );
  @override
  late final GeneratedColumn<int> rawAmount = GeneratedColumn<int>(
    'raw_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleVersionMeta = const VerificationMeta(
    'ruleVersion',
  );
  @override
  late final GeneratedColumn<String> ruleVersion = GeneratedColumn<String>(
    'rule_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDayMeta = const VerificationMeta(
    'localDay',
  );
  @override
  late final GeneratedColumn<String> localDay = GeneratedColumn<String>(
    'local_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _provisionalMeta = const VerificationMeta(
    'provisional',
  );
  @override
  late final GeneratedColumn<bool> provisional = GeneratedColumn<bool>(
    'provisional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("provisional" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _supersededMeta = const VerificationMeta(
    'superseded',
  );
  @override
  late final GeneratedColumn<bool> superseded = GeneratedColumn<bool>(
    'superseded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("superseded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    completionId,
    attribute,
    amount,
    rawAmount,
    kind,
    ruleVersion,
    localDay,
    provisional,
    superseded,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('completion_id')) {
      context.handle(
        _completionIdMeta,
        completionId.isAcceptableOrUnknown(
          data['completion_id']!,
          _completionIdMeta,
        ),
      );
    }
    if (data.containsKey('attribute')) {
      context.handle(
        _attributeMeta,
        attribute.isAcceptableOrUnknown(data['attribute']!, _attributeMeta),
      );
    } else if (isInserting) {
      context.missing(_attributeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('raw_amount')) {
      context.handle(
        _rawAmountMeta,
        rawAmount.isAcceptableOrUnknown(data['raw_amount']!, _rawAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_rawAmountMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('rule_version')) {
      context.handle(
        _ruleVersionMeta,
        ruleVersion.isAcceptableOrUnknown(
          data['rule_version']!,
          _ruleVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ruleVersionMeta);
    }
    if (data.containsKey('local_day')) {
      context.handle(
        _localDayMeta,
        localDay.isAcceptableOrUnknown(data['local_day']!, _localDayMeta),
      );
    } else if (isInserting) {
      context.missing(_localDayMeta);
    }
    if (data.containsKey('provisional')) {
      context.handle(
        _provisionalMeta,
        provisional.isAcceptableOrUnknown(
          data['provisional']!,
          _provisionalMeta,
        ),
      );
    }
    if (data.containsKey('superseded')) {
      context.handle(
        _supersededMeta,
        superseded.isAcceptableOrUnknown(data['superseded']!, _supersededMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      completionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completion_id'],
      ),
      attribute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribute'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      rawAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}raw_amount'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      ruleVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_version'],
      )!,
      localDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_day'],
      )!,
      provisional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}provisional'],
      )!,
      superseded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}superseded'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LedgerEntriesTable createAlias(String alias) {
    return $LedgerEntriesTable(attachedDatabase, alias);
  }
}

class LedgerRow extends DataClass implements Insertable<LedgerRow> {
  final String id;
  final String? completionId;
  final String attribute;
  final int amount;
  final int rawAmount;

  /// `grant` or `reversal`.
  final String kind;
  final String ruleVersion;
  final String localDay;
  final bool provisional;
  final bool superseded;
  final DateTime createdAt;
  const LedgerRow({
    required this.id,
    this.completionId,
    required this.attribute,
    required this.amount,
    required this.rawAmount,
    required this.kind,
    required this.ruleVersion,
    required this.localDay,
    required this.provisional,
    required this.superseded,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || completionId != null) {
      map['completion_id'] = Variable<String>(completionId);
    }
    map['attribute'] = Variable<String>(attribute);
    map['amount'] = Variable<int>(amount);
    map['raw_amount'] = Variable<int>(rawAmount);
    map['kind'] = Variable<String>(kind);
    map['rule_version'] = Variable<String>(ruleVersion);
    map['local_day'] = Variable<String>(localDay);
    map['provisional'] = Variable<bool>(provisional);
    map['superseded'] = Variable<bool>(superseded);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesCompanion(
      id: Value(id),
      completionId: completionId == null && nullToAbsent
          ? const Value.absent()
          : Value(completionId),
      attribute: Value(attribute),
      amount: Value(amount),
      rawAmount: Value(rawAmount),
      kind: Value(kind),
      ruleVersion: Value(ruleVersion),
      localDay: Value(localDay),
      provisional: Value(provisional),
      superseded: Value(superseded),
      createdAt: Value(createdAt),
    );
  }

  factory LedgerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerRow(
      id: serializer.fromJson<String>(json['id']),
      completionId: serializer.fromJson<String?>(json['completionId']),
      attribute: serializer.fromJson<String>(json['attribute']),
      amount: serializer.fromJson<int>(json['amount']),
      rawAmount: serializer.fromJson<int>(json['rawAmount']),
      kind: serializer.fromJson<String>(json['kind']),
      ruleVersion: serializer.fromJson<String>(json['ruleVersion']),
      localDay: serializer.fromJson<String>(json['localDay']),
      provisional: serializer.fromJson<bool>(json['provisional']),
      superseded: serializer.fromJson<bool>(json['superseded']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'completionId': serializer.toJson<String?>(completionId),
      'attribute': serializer.toJson<String>(attribute),
      'amount': serializer.toJson<int>(amount),
      'rawAmount': serializer.toJson<int>(rawAmount),
      'kind': serializer.toJson<String>(kind),
      'ruleVersion': serializer.toJson<String>(ruleVersion),
      'localDay': serializer.toJson<String>(localDay),
      'provisional': serializer.toJson<bool>(provisional),
      'superseded': serializer.toJson<bool>(superseded),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LedgerRow copyWith({
    String? id,
    Value<String?> completionId = const Value.absent(),
    String? attribute,
    int? amount,
    int? rawAmount,
    String? kind,
    String? ruleVersion,
    String? localDay,
    bool? provisional,
    bool? superseded,
    DateTime? createdAt,
  }) => LedgerRow(
    id: id ?? this.id,
    completionId: completionId.present ? completionId.value : this.completionId,
    attribute: attribute ?? this.attribute,
    amount: amount ?? this.amount,
    rawAmount: rawAmount ?? this.rawAmount,
    kind: kind ?? this.kind,
    ruleVersion: ruleVersion ?? this.ruleVersion,
    localDay: localDay ?? this.localDay,
    provisional: provisional ?? this.provisional,
    superseded: superseded ?? this.superseded,
    createdAt: createdAt ?? this.createdAt,
  );
  LedgerRow copyWithCompanion(LedgerEntriesCompanion data) {
    return LedgerRow(
      id: data.id.present ? data.id.value : this.id,
      completionId: data.completionId.present
          ? data.completionId.value
          : this.completionId,
      attribute: data.attribute.present ? data.attribute.value : this.attribute,
      amount: data.amount.present ? data.amount.value : this.amount,
      rawAmount: data.rawAmount.present ? data.rawAmount.value : this.rawAmount,
      kind: data.kind.present ? data.kind.value : this.kind,
      ruleVersion: data.ruleVersion.present
          ? data.ruleVersion.value
          : this.ruleVersion,
      localDay: data.localDay.present ? data.localDay.value : this.localDay,
      provisional: data.provisional.present
          ? data.provisional.value
          : this.provisional,
      superseded: data.superseded.present
          ? data.superseded.value
          : this.superseded,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerRow(')
          ..write('id: $id, ')
          ..write('completionId: $completionId, ')
          ..write('attribute: $attribute, ')
          ..write('amount: $amount, ')
          ..write('rawAmount: $rawAmount, ')
          ..write('kind: $kind, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('localDay: $localDay, ')
          ..write('provisional: $provisional, ')
          ..write('superseded: $superseded, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    completionId,
    attribute,
    amount,
    rawAmount,
    kind,
    ruleVersion,
    localDay,
    provisional,
    superseded,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerRow &&
          other.id == this.id &&
          other.completionId == this.completionId &&
          other.attribute == this.attribute &&
          other.amount == this.amount &&
          other.rawAmount == this.rawAmount &&
          other.kind == this.kind &&
          other.ruleVersion == this.ruleVersion &&
          other.localDay == this.localDay &&
          other.provisional == this.provisional &&
          other.superseded == this.superseded &&
          other.createdAt == this.createdAt);
}

class LedgerEntriesCompanion extends UpdateCompanion<LedgerRow> {
  final Value<String> id;
  final Value<String?> completionId;
  final Value<String> attribute;
  final Value<int> amount;
  final Value<int> rawAmount;
  final Value<String> kind;
  final Value<String> ruleVersion;
  final Value<String> localDay;
  final Value<bool> provisional;
  final Value<bool> superseded;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.completionId = const Value.absent(),
    this.attribute = const Value.absent(),
    this.amount = const Value.absent(),
    this.rawAmount = const Value.absent(),
    this.kind = const Value.absent(),
    this.ruleVersion = const Value.absent(),
    this.localDay = const Value.absent(),
    this.provisional = const Value.absent(),
    this.superseded = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    required String id,
    this.completionId = const Value.absent(),
    required String attribute,
    required int amount,
    required int rawAmount,
    required String kind,
    required String ruleVersion,
    required String localDay,
    this.provisional = const Value.absent(),
    this.superseded = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       attribute = Value(attribute),
       amount = Value(amount),
       rawAmount = Value(rawAmount),
       kind = Value(kind),
       ruleVersion = Value(ruleVersion),
       localDay = Value(localDay),
       createdAt = Value(createdAt);
  static Insertable<LedgerRow> custom({
    Expression<String>? id,
    Expression<String>? completionId,
    Expression<String>? attribute,
    Expression<int>? amount,
    Expression<int>? rawAmount,
    Expression<String>? kind,
    Expression<String>? ruleVersion,
    Expression<String>? localDay,
    Expression<bool>? provisional,
    Expression<bool>? superseded,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (completionId != null) 'completion_id': completionId,
      if (attribute != null) 'attribute': attribute,
      if (amount != null) 'amount': amount,
      if (rawAmount != null) 'raw_amount': rawAmount,
      if (kind != null) 'kind': kind,
      if (ruleVersion != null) 'rule_version': ruleVersion,
      if (localDay != null) 'local_day': localDay,
      if (provisional != null) 'provisional': provisional,
      if (superseded != null) 'superseded': superseded,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerEntriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? completionId,
    Value<String>? attribute,
    Value<int>? amount,
    Value<int>? rawAmount,
    Value<String>? kind,
    Value<String>? ruleVersion,
    Value<String>? localDay,
    Value<bool>? provisional,
    Value<bool>? superseded,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      completionId: completionId ?? this.completionId,
      attribute: attribute ?? this.attribute,
      amount: amount ?? this.amount,
      rawAmount: rawAmount ?? this.rawAmount,
      kind: kind ?? this.kind,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      localDay: localDay ?? this.localDay,
      provisional: provisional ?? this.provisional,
      superseded: superseded ?? this.superseded,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (completionId.present) {
      map['completion_id'] = Variable<String>(completionId.value);
    }
    if (attribute.present) {
      map['attribute'] = Variable<String>(attribute.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (rawAmount.present) {
      map['raw_amount'] = Variable<int>(rawAmount.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (ruleVersion.present) {
      map['rule_version'] = Variable<String>(ruleVersion.value);
    }
    if (localDay.present) {
      map['local_day'] = Variable<String>(localDay.value);
    }
    if (provisional.present) {
      map['provisional'] = Variable<bool>(provisional.value);
    }
    if (superseded.present) {
      map['superseded'] = Variable<bool>(superseded.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('completionId: $completionId, ')
          ..write('attribute: $attribute, ')
          ..write('amount: $amount, ')
          ..write('rawAmount: $rawAmount, ')
          ..write('kind: $kind, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('localDay: $localDay, ')
          ..write('provisional: $provisional, ')
          ..write('superseded: $superseded, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnlockedAchievementsTable extends UnlockedAchievements
    with TableInfo<$UnlockedAchievementsTable, AchievementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnlockedAchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta(
    'unlockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
    'unlocked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, unlockedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unlocked_achievements';
  @override
  VerificationContext validateIntegrity(
    Insertable<AchievementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
        _unlockedAtMeta,
        unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_unlockedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AchievementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AchievementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      unlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}unlocked_at'],
      )!,
    );
  }

  @override
  $UnlockedAchievementsTable createAlias(String alias) {
    return $UnlockedAchievementsTable(attachedDatabase, alias);
  }
}

class AchievementRow extends DataClass implements Insertable<AchievementRow> {
  final String id;
  final DateTime unlockedAt;
  const AchievementRow({required this.id, required this.unlockedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    return map;
  }

  UnlockedAchievementsCompanion toCompanion(bool nullToAbsent) {
    return UnlockedAchievementsCompanion(
      id: Value(id),
      unlockedAt: Value(unlockedAt),
    );
  }

  factory AchievementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AchievementRow(
      id: serializer.fromJson<String>(json['id']),
      unlockedAt: serializer.fromJson<DateTime>(json['unlockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'unlockedAt': serializer.toJson<DateTime>(unlockedAt),
    };
  }

  AchievementRow copyWith({String? id, DateTime? unlockedAt}) => AchievementRow(
    id: id ?? this.id,
    unlockedAt: unlockedAt ?? this.unlockedAt,
  );
  AchievementRow copyWithCompanion(UnlockedAchievementsCompanion data) {
    return AchievementRow(
      id: data.id.present ? data.id.value : this.id,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AchievementRow(')
          ..write('id: $id, ')
          ..write('unlockedAt: $unlockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, unlockedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AchievementRow &&
          other.id == this.id &&
          other.unlockedAt == this.unlockedAt);
}

class UnlockedAchievementsCompanion extends UpdateCompanion<AchievementRow> {
  final Value<String> id;
  final Value<DateTime> unlockedAt;
  final Value<int> rowid;
  const UnlockedAchievementsCompanion({
    this.id = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnlockedAchievementsCompanion.insert({
    required String id,
    required DateTime unlockedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       unlockedAt = Value(unlockedAt);
  static Insertable<AchievementRow> custom({
    Expression<String>? id,
    Expression<DateTime>? unlockedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnlockedAchievementsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? unlockedAt,
    Value<int>? rowid,
  }) {
    return UnlockedAchievementsCompanion(
      id: id ?? this.id,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnlockedAchievementsCompanion(')
          ..write('id: $id, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayMarksTable extends DayMarks
    with TableInfo<$DayMarksTable, DayMarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayMarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localDayMeta = const VerificationMeta(
    'localDay',
  );
  @override
  late final GeneratedColumn<String> localDay = GeneratedColumn<String>(
    'local_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restMeta = const VerificationMeta('rest');
  @override
  late final GeneratedColumn<bool> rest = GeneratedColumn<bool>(
    'rest',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rest" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pausedMeta = const VerificationMeta('paused');
  @override
  late final GeneratedColumn<bool> paused = GeneratedColumn<bool>(
    'paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [localDay, rest, paused];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_marks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayMarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_day')) {
      context.handle(
        _localDayMeta,
        localDay.isAcceptableOrUnknown(data['local_day']!, _localDayMeta),
      );
    } else if (isInserting) {
      context.missing(_localDayMeta);
    }
    if (data.containsKey('rest')) {
      context.handle(
        _restMeta,
        rest.isAcceptableOrUnknown(data['rest']!, _restMeta),
      );
    }
    if (data.containsKey('paused')) {
      context.handle(
        _pausedMeta,
        paused.isAcceptableOrUnknown(data['paused']!, _pausedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localDay};
  @override
  DayMarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayMarkRow(
      localDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_day'],
      )!,
      rest: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rest'],
      )!,
      paused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paused'],
      )!,
    );
  }

  @override
  $DayMarksTable createAlias(String alias) {
    return $DayMarksTable(attachedDatabase, alias);
  }
}

class DayMarkRow extends DataClass implements Insertable<DayMarkRow> {
  final String localDay;
  final bool rest;
  final bool paused;
  const DayMarkRow({
    required this.localDay,
    required this.rest,
    required this.paused,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_day'] = Variable<String>(localDay);
    map['rest'] = Variable<bool>(rest);
    map['paused'] = Variable<bool>(paused);
    return map;
  }

  DayMarksCompanion toCompanion(bool nullToAbsent) {
    return DayMarksCompanion(
      localDay: Value(localDay),
      rest: Value(rest),
      paused: Value(paused),
    );
  }

  factory DayMarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayMarkRow(
      localDay: serializer.fromJson<String>(json['localDay']),
      rest: serializer.fromJson<bool>(json['rest']),
      paused: serializer.fromJson<bool>(json['paused']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localDay': serializer.toJson<String>(localDay),
      'rest': serializer.toJson<bool>(rest),
      'paused': serializer.toJson<bool>(paused),
    };
  }

  DayMarkRow copyWith({String? localDay, bool? rest, bool? paused}) =>
      DayMarkRow(
        localDay: localDay ?? this.localDay,
        rest: rest ?? this.rest,
        paused: paused ?? this.paused,
      );
  DayMarkRow copyWithCompanion(DayMarksCompanion data) {
    return DayMarkRow(
      localDay: data.localDay.present ? data.localDay.value : this.localDay,
      rest: data.rest.present ? data.rest.value : this.rest,
      paused: data.paused.present ? data.paused.value : this.paused,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayMarkRow(')
          ..write('localDay: $localDay, ')
          ..write('rest: $rest, ')
          ..write('paused: $paused')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localDay, rest, paused);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayMarkRow &&
          other.localDay == this.localDay &&
          other.rest == this.rest &&
          other.paused == this.paused);
}

class DayMarksCompanion extends UpdateCompanion<DayMarkRow> {
  final Value<String> localDay;
  final Value<bool> rest;
  final Value<bool> paused;
  final Value<int> rowid;
  const DayMarksCompanion({
    this.localDay = const Value.absent(),
    this.rest = const Value.absent(),
    this.paused = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayMarksCompanion.insert({
    required String localDay,
    this.rest = const Value.absent(),
    this.paused = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localDay = Value(localDay);
  static Insertable<DayMarkRow> custom({
    Expression<String>? localDay,
    Expression<bool>? rest,
    Expression<bool>? paused,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localDay != null) 'local_day': localDay,
      if (rest != null) 'rest': rest,
      if (paused != null) 'paused': paused,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayMarksCompanion copyWith({
    Value<String>? localDay,
    Value<bool>? rest,
    Value<bool>? paused,
    Value<int>? rowid,
  }) {
    return DayMarksCompanion(
      localDay: localDay ?? this.localDay,
      rest: rest ?? this.rest,
      paused: paused ?? this.paused,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localDay.present) {
      map['local_day'] = Variable<String>(localDay.value);
    }
    if (rest.present) {
      map['rest'] = Variable<bool>(rest.value);
    }
    if (paused.present) {
      map['paused'] = Variable<bool>(paused.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayMarksCompanion(')
          ..write('localDay: $localDay, ')
          ..write('rest: $rest, ')
          ..write('paused: $paused, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValueRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValueRow extends DataClass implements Insertable<KeyValueRow> {
  final String key;
  final String value;
  const KeyValueRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValueRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValueRow copyWith({String? key, String? value}) =>
      KeyValueRow(key: key ?? this.key, value: value ?? this.value);
  KeyValueRow copyWithCompanion(KeyValuesCompanion data) {
    return KeyValueRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValueRow &&
          other.key == this.key &&
          other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValueRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValueRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxEntriesTable extends OutboxEntries
    with TableInfo<$OutboxEntriesTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entity,
    entityId,
    op,
    payload,
    attempts,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxEntriesTable createAlias(String alias) {
    return $OutboxEntriesTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int id;
  final String entity;
  final String entityId;
  final String op;
  final String payload;
  final int attempts;
  final DateTime createdAt;
  const OutboxRow({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payload,
    required this.attempts,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['op'] = Variable<String>(op);
    map['payload'] = Variable<String>(payload);
    map['attempts'] = Variable<int>(attempts);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntriesCompanion(
      id: Value(id),
      entity: Value(entity),
      entityId: Value(entityId),
      op: Value(op),
      payload: Value(payload),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<int>(json['id']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      op: serializer.fromJson<String>(json['op']),
      payload: serializer.fromJson<String>(json['payload']),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'op': serializer.toJson<String>(op),
      'payload': serializer.toJson<String>(payload),
      'attempts': serializer.toJson<int>(attempts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxRow copyWith({
    int? id,
    String? entity,
    String? entityId,
    String? op,
    String? payload,
    int? attempts,
    DateTime? createdAt,
  }) => OutboxRow(
    id: id ?? this.id,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    op: op ?? this.op,
    payload: payload ?? this.payload,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxRow copyWithCompanion(OutboxEntriesCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      op: data.op.present ? data.op.value : this.op,
      payload: data.payload.present ? data.payload.value : this.payload,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entity, entityId, op, payload, attempts, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.op == this.op &&
          other.payload == this.payload &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt);
}

class OutboxEntriesCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> id;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> op;
  final Value<String> payload;
  final Value<int> attempts;
  final Value<DateTime> createdAt;
  const OutboxEntriesCompanion({
    this.id = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.op = const Value.absent(),
    this.payload = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String entity,
    required String entityId,
    required String op,
    required String payload,
    this.attempts = const Value.absent(),
    required DateTime createdAt,
  }) : entity = Value(entity),
       entityId = Value(entityId),
       op = Value(op),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<OutboxRow> custom({
    Expression<int>? id,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? op,
    Expression<String>? payload,
    Expression<int>? attempts,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (op != null) 'op': op,
      if (payload != null) 'payload': payload,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? op,
    Value<String>? payload,
    Value<int>? attempts,
    Value<DateTime>? createdAt,
  }) {
    return OutboxEntriesCompanion(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntriesCompanion(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $QuestsTable quests = $QuestsTable(this);
  late final $SubtasksTable subtasks = $SubtasksTable(this);
  late final $CompletionsTable completions = $CompletionsTable(this);
  late final $EvaluationsTable evaluations = $EvaluationsTable(this);
  late final $LedgerEntriesTable ledgerEntries = $LedgerEntriesTable(this);
  late final $UnlockedAchievementsTable unlockedAchievements =
      $UnlockedAchievementsTable(this);
  late final $DayMarksTable dayMarks = $DayMarksTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    quests,
    subtasks,
    completions,
    evaluations,
    ledgerEntries,
    unlockedAchievements,
    dayMarks,
    keyValues,
    outboxEntries,
  ];
}

typedef $$QuestsTableCreateCompanionBuilder = QuestsCompanion Function({
  required String id,
  Value<String?> parentId,
  required String tier,
  required String title,
  Value<String> notes,
  Value<String?> category,
  Value<int> priority,
  Value<String> status,
  Value<DateTime?> dueAt,
  Value<int?> estimatedMinutes,
  Value<String> recurrence,
  Value<String?> intention,
  Value<String> shareLevel,
  Value<int?> remindAt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$QuestsTableUpdateCompanionBuilder = QuestsCompanion Function({
  Value<String> id,
  Value<String?> parentId,
  Value<String> tier,
  Value<String> title,
  Value<String> notes,
  Value<String?> category,
  Value<int> priority,
  Value<String> status,
  Value<DateTime?> dueAt,
  Value<int?> estimatedMinutes,
  Value<String> recurrence,
  Value<String?> intention,
  Value<String> shareLevel,
  Value<int?> remindAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$QuestsTableReferences
    extends BaseReferences<_$AppDatabase, $QuestsTable, QuestRow> {
  $$QuestsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SubtasksTable, List<SubtaskRow>>
  _subtasksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.subtasks,
    aliasName: 'quests__id__subtasks__quest_id',
  );

  $$SubtasksTableProcessedTableManager get subtasksRefs {
    final manager = $$SubtasksTableTableManager(
      $_db,
      $_db.subtasks,
    ).filter((f) => f.questId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_subtasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CompletionsTable, List<CompletionRow>>
  _completionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.completions,
    aliasName: 'quests__id__completions__quest_id',
  );

  $$CompletionsTableProcessedTableManager get completionsRefs {
    final manager = $$CompletionsTableTableManager(
      $_db,
      $_db.completions,
    ).filter((f) => f.questId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_completionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$QuestsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestsTable> {
  $$QuestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intention => $composableBuilder(
    column: $table.intention,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shareLevel => $composableBuilder(
    column: $table.shareLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> subtasksRefs(
    Expression<bool> Function($$SubtasksTableFilterComposer f) f,
  ) {
    final $$SubtasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subtasks,
      getReferencedColumn: (t) => t.questId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubtasksTableFilterComposer(
            $db: $db,
            $table: $db.subtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> completionsRefs(
    Expression<bool> Function($$CompletionsTableFilterComposer f) f,
  ) {
    final $$CompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.questId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableFilterComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuestsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestsTable> {
  $$QuestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intention => $composableBuilder(
    column: $table.intention,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shareLevel => $composableBuilder(
    column: $table.shareLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestsTable> {
  $$QuestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get intention =>
      $composableBuilder(column: $table.intention, builder: (column) => column);

  GeneratedColumn<String> get shareLevel => $composableBuilder(
    column: $table.shareLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remindAt =>
      $composableBuilder(column: $table.remindAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> subtasksRefs<T extends Object>(
    Expression<T> Function($$SubtasksTableAnnotationComposer a) f,
  ) {
    final $$SubtasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subtasks,
      getReferencedColumn: (t) => t.questId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubtasksTableAnnotationComposer(
            $db: $db,
            $table: $db.subtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> completionsRefs<T extends Object>(
    Expression<T> Function($$CompletionsTableAnnotationComposer a) f,
  ) {
    final $$CompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.questId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuestsTable,
          QuestRow,
          $$QuestsTableFilterComposer,
          $$QuestsTableOrderingComposer,
          $$QuestsTableAnnotationComposer,
          $$QuestsTableCreateCompanionBuilder,
          $$QuestsTableUpdateCompanionBuilder,
          (QuestRow, $$QuestsTableReferences),
          QuestRow,
          PrefetchHooks Function({bool subtasksRefs, bool completionsRefs})
        > {
  $$QuestsTableTableManager(_$AppDatabase db, $QuestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> tier = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<int?> estimatedMinutes = const Value.absent(),
                Value<String> recurrence = const Value.absent(),
                Value<String?> intention = const Value.absent(),
                Value<String> shareLevel = const Value.absent(),
                Value<int?> remindAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestsCompanion(
                id: id,
                parentId: parentId,
                tier: tier,
                title: title,
                notes: notes,
                category: category,
                priority: priority,
                status: status,
                dueAt: dueAt,
                estimatedMinutes: estimatedMinutes,
                recurrence: recurrence,
                intention: intention,
                shareLevel: shareLevel,
                remindAt: remindAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parentId = const Value.absent(),
                required String tier,
                required String title,
                Value<String> notes = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<int?> estimatedMinutes = const Value.absent(),
                Value<String> recurrence = const Value.absent(),
                Value<String?> intention = const Value.absent(),
                Value<String> shareLevel = const Value.absent(),
                Value<int?> remindAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestsCompanion.insert(
                id: id,
                parentId: parentId,
                tier: tier,
                title: title,
                notes: notes,
                category: category,
                priority: priority,
                status: status,
                dueAt: dueAt,
                estimatedMinutes: estimatedMinutes,
                recurrence: recurrence,
                intention: intention,
                shareLevel: shareLevel,
                remindAt: remindAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuestsTable, QuestRow>(table),
                  $$QuestsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({subtasksRefs = false, completionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (subtasksRefs) db.subtasks,
                    if (completionsRefs) db.completions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (subtasksRefs)
                        await $_getPrefetchedDataByColumns<
                          QuestRow,
                          $QuestsTable,
                          SubtaskRow,
                          $SubtasksTable
                        >(
                          currentTable: table,
                          referencedTable: $$QuestsTableReferences
                              ._subtasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuestsTableReferences(
                                db,
                                table,
                                p0,
                              ).subtasksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'quest_id',
                          typedResults: items,
                        ),
                      if (completionsRefs)
                        await $_getPrefetchedDataByColumns<
                          QuestRow,
                          $QuestsTable,
                          CompletionRow,
                          $CompletionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$QuestsTableReferences
                              ._completionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuestsTableReferences(
                                db,
                                table,
                                p0,
                              ).completionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'quest_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$QuestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuestsTable,
      QuestRow,
      $$QuestsTableFilterComposer,
      $$QuestsTableOrderingComposer,
      $$QuestsTableAnnotationComposer,
      $$QuestsTableCreateCompanionBuilder,
      $$QuestsTableUpdateCompanionBuilder,
      (QuestRow, $$QuestsTableReferences),
      QuestRow,
      PrefetchHooks Function({bool subtasksRefs, bool completionsRefs})
    >;
typedef $$SubtasksTableCreateCompanionBuilder = SubtasksCompanion Function({
  required String id,
  required String questId,
  required String title,
  Value<bool> done,
  Value<int> position,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$SubtasksTableUpdateCompanionBuilder = SubtasksCompanion Function({
  Value<String> id,
  Value<String> questId,
  Value<String> title,
  Value<bool> done,
  Value<int> position,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$SubtasksTableReferences
    extends BaseReferences<_$AppDatabase, $SubtasksTable, SubtaskRow> {
  $$SubtasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $QuestsTable _questIdTable(_$AppDatabase db) =>
      db.quests.createAlias('subtasks__quest_id__quests__id');

  $$QuestsTableProcessedTableManager get questId {
    final $_column = $_itemColumn<String>('quest_id')!;

    final manager = $$QuestsTableTableManager(
      $_db,
      $_db.quests,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SubtasksTableFilterComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$QuestsTableFilterComposer get questId {
    final $$QuestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questId,
      referencedTable: $db.quests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestsTableFilterComposer(
            $db: $db,
            $table: $db.quests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableOrderingComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuestsTableOrderingComposer get questId {
    final $$QuestsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questId,
      referencedTable: $db.quests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestsTableOrderingComposer(
            $db: $db,
            $table: $db.quests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$QuestsTableAnnotationComposer get questId {
    final $$QuestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questId,
      referencedTable: $db.quests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestsTableAnnotationComposer(
            $db: $db,
            $table: $db.quests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubtasksTable,
          SubtaskRow,
          $$SubtasksTableFilterComposer,
          $$SubtasksTableOrderingComposer,
          $$SubtasksTableAnnotationComposer,
          $$SubtasksTableCreateCompanionBuilder,
          $$SubtasksTableUpdateCompanionBuilder,
          (SubtaskRow, $$SubtasksTableReferences),
          SubtaskRow,
          PrefetchHooks Function({bool questId})
        > {
  $$SubtasksTableTableManager(_$AppDatabase db, $SubtasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubtasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubtasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubtasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> questId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubtasksCompanion(
                id: id,
                questId: questId,
                title: title,
                done: done,
                position: position,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String questId,
                required String title,
                Value<bool> done = const Value.absent(),
                Value<int> position = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubtasksCompanion.insert(
                id: id,
                questId: questId,
                title: title,
                done: done,
                position: position,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubtasksTable, SubtaskRow>(table),
                  $$SubtasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({questId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (questId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.questId,
                        referencedTable: $$SubtasksTableReferences
                            ._questIdTable(db),
                        referencedColumn: $$SubtasksTableReferences
                            ._questIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SubtasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubtasksTable,
      SubtaskRow,
      $$SubtasksTableFilterComposer,
      $$SubtasksTableOrderingComposer,
      $$SubtasksTableAnnotationComposer,
      $$SubtasksTableCreateCompanionBuilder,
      $$SubtasksTableUpdateCompanionBuilder,
      (SubtaskRow, $$SubtasksTableReferences),
      SubtaskRow,
      PrefetchHooks Function({bool questId})
    >;
typedef $$CompletionsTableCreateCompanionBuilder =
    CompletionsCompanion Function({
      required String id,
      required String questId,
      required String occurrenceDay,
      required String localDay,
      required DateTime completedAt,
      Value<int?> declaredMinutes,
      Value<int?> trackedMinutes,
      Value<String> state,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CompletionsTableUpdateCompanionBuilder =
    CompletionsCompanion Function({
      Value<String> id,
      Value<String> questId,
      Value<String> occurrenceDay,
      Value<String> localDay,
      Value<DateTime> completedAt,
      Value<int?> declaredMinutes,
      Value<int?> trackedMinutes,
      Value<String> state,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CompletionsTableReferences
    extends BaseReferences<_$AppDatabase, $CompletionsTable, CompletionRow> {
  $$CompletionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $QuestsTable _questIdTable(_$AppDatabase db) =>
      db.quests.createAlias('completions__quest_id__quests__id');

  $$QuestsTableProcessedTableManager get questId {
    final $_column = $_itemColumn<String>('quest_id')!;

    final manager = $$QuestsTableTableManager(
      $_db,
      $_db.quests,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EvaluationsTable, List<EvaluationRow>>
  _evaluationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.evaluations,
    aliasName: 'completions__id__evaluations__completion_id',
  );

  $$EvaluationsTableProcessedTableManager get evaluationsRefs {
    final manager = $$EvaluationsTableTableManager(
      $_db,
      $_db.evaluations,
    ).filter((f) => f.completionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_evaluationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $CompletionsTable> {
  $$CompletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurrenceDay => $composableBuilder(
    column: $table.occurrenceDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDay => $composableBuilder(
    column: $table.localDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get declaredMinutes => $composableBuilder(
    column: $table.declaredMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackedMinutes => $composableBuilder(
    column: $table.trackedMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$QuestsTableFilterComposer get questId {
    final $$QuestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questId,
      referencedTable: $db.quests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestsTableFilterComposer(
            $db: $db,
            $table: $db.quests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> evaluationsRefs(
    Expression<bool> Function($$EvaluationsTableFilterComposer f) f,
  ) {
    final $$EvaluationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evaluations,
      getReferencedColumn: (t) => t.completionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvaluationsTableFilterComposer(
            $db: $db,
            $table: $db.evaluations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletionsTable> {
  $$CompletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurrenceDay => $composableBuilder(
    column: $table.occurrenceDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDay => $composableBuilder(
    column: $table.localDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get declaredMinutes => $composableBuilder(
    column: $table.declaredMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackedMinutes => $composableBuilder(
    column: $table.trackedMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuestsTableOrderingComposer get questId {
    final $$QuestsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questId,
      referencedTable: $db.quests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestsTableOrderingComposer(
            $db: $db,
            $table: $db.quests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletionsTable> {
  $$CompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get occurrenceDay => $composableBuilder(
    column: $table.occurrenceDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localDay =>
      $composableBuilder(column: $table.localDay, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get declaredMinutes => $composableBuilder(
    column: $table.declaredMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackedMinutes => $composableBuilder(
    column: $table.trackedMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$QuestsTableAnnotationComposer get questId {
    final $$QuestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questId,
      referencedTable: $db.quests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestsTableAnnotationComposer(
            $db: $db,
            $table: $db.quests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> evaluationsRefs<T extends Object>(
    Expression<T> Function($$EvaluationsTableAnnotationComposer a) f,
  ) {
    final $$EvaluationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evaluations,
      getReferencedColumn: (t) => t.completionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvaluationsTableAnnotationComposer(
            $db: $db,
            $table: $db.evaluations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompletionsTable,
          CompletionRow,
          $$CompletionsTableFilterComposer,
          $$CompletionsTableOrderingComposer,
          $$CompletionsTableAnnotationComposer,
          $$CompletionsTableCreateCompanionBuilder,
          $$CompletionsTableUpdateCompanionBuilder,
          (CompletionRow, $$CompletionsTableReferences),
          CompletionRow,
          PrefetchHooks Function({bool questId, bool evaluationsRefs})
        > {
  $$CompletionsTableTableManager(_$AppDatabase db, $CompletionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> questId = const Value.absent(),
                Value<String> occurrenceDay = const Value.absent(),
                Value<String> localDay = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int?> declaredMinutes = const Value.absent(),
                Value<int?> trackedMinutes = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompletionsCompanion(
                id: id,
                questId: questId,
                occurrenceDay: occurrenceDay,
                localDay: localDay,
                completedAt: completedAt,
                declaredMinutes: declaredMinutes,
                trackedMinutes: trackedMinutes,
                state: state,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String questId,
                required String occurrenceDay,
                required String localDay,
                required DateTime completedAt,
                Value<int?> declaredMinutes = const Value.absent(),
                Value<int?> trackedMinutes = const Value.absent(),
                Value<String> state = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CompletionsCompanion.insert(
                id: id,
                questId: questId,
                occurrenceDay: occurrenceDay,
                localDay: localDay,
                completedAt: completedAt,
                declaredMinutes: declaredMinutes,
                trackedMinutes: trackedMinutes,
                state: state,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CompletionsTable, CompletionRow>(table),
                  $$CompletionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({questId = false, evaluationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (evaluationsRefs) db.evaluations],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (questId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.questId,
                        referencedTable: $$CompletionsTableReferences
                            ._questIdTable(db),
                        referencedColumn: $$CompletionsTableReferences
                            ._questIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (evaluationsRefs)
                    await $_getPrefetchedDataByColumns<
                      CompletionRow,
                      $CompletionsTable,
                      EvaluationRow,
                      $EvaluationsTable
                    >(
                      currentTable: table,
                      referencedTable: $$CompletionsTableReferences
                          ._evaluationsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CompletionsTableReferences(
                            db,
                            table,
                            p0,
                          ).evaluationsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'completion_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CompletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompletionsTable,
      CompletionRow,
      $$CompletionsTableFilterComposer,
      $$CompletionsTableOrderingComposer,
      $$CompletionsTableAnnotationComposer,
      $$CompletionsTableCreateCompanionBuilder,
      $$CompletionsTableUpdateCompanionBuilder,
      (CompletionRow, $$CompletionsTableReferences),
      CompletionRow,
      PrefetchHooks Function({bool questId, bool evaluationsRefs})
    >;
typedef $$EvaluationsTableCreateCompanionBuilder =
    EvaluationsCompanion Function({
      required String completionId,
      required String localDay,
      required String category,
      required String similarityKey,
      required int effectiveMinutes,
      required int totalXp,
      required bool trivial,
      required String source,
      required String proposalJson,
      required String resultJson,
      Value<bool> provisional,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$EvaluationsTableUpdateCompanionBuilder =
    EvaluationsCompanion Function({
      Value<String> completionId,
      Value<String> localDay,
      Value<String> category,
      Value<String> similarityKey,
      Value<int> effectiveMinutes,
      Value<int> totalXp,
      Value<bool> trivial,
      Value<String> source,
      Value<String> proposalJson,
      Value<String> resultJson,
      Value<bool> provisional,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$EvaluationsTableReferences
    extends BaseReferences<_$AppDatabase, $EvaluationsTable, EvaluationRow> {
  $$EvaluationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CompletionsTable _completionIdTable(_$AppDatabase db) =>
      db.completions.createAlias('evaluations__completion_id__completions__id');

  $$CompletionsTableProcessedTableManager get completionId {
    final $_column = $_itemColumn<String>('completion_id')!;

    final manager = $$CompletionsTableTableManager(
      $_db,
      $_db.completions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_completionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EvaluationsTableFilterComposer
    extends Composer<_$AppDatabase, $EvaluationsTable> {
  $$EvaluationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localDay => $composableBuilder(
    column: $table.localDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get similarityKey => $composableBuilder(
    column: $table.similarityKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get effectiveMinutes => $composableBuilder(
    column: $table.effectiveMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trivial => $composableBuilder(
    column: $table.trivial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proposalJson => $composableBuilder(
    column: $table.proposalJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get provisional => $composableBuilder(
    column: $table.provisional,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CompletionsTableFilterComposer get completionId {
    final $$CompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completionId,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableFilterComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvaluationsTableOrderingComposer
    extends Composer<_$AppDatabase, $EvaluationsTable> {
  $$EvaluationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localDay => $composableBuilder(
    column: $table.localDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get similarityKey => $composableBuilder(
    column: $table.similarityKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effectiveMinutes => $composableBuilder(
    column: $table.effectiveMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trivial => $composableBuilder(
    column: $table.trivial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proposalJson => $composableBuilder(
    column: $table.proposalJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get provisional => $composableBuilder(
    column: $table.provisional,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CompletionsTableOrderingComposer get completionId {
    final $$CompletionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completionId,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableOrderingComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvaluationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EvaluationsTable> {
  $$EvaluationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localDay =>
      $composableBuilder(column: $table.localDay, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get similarityKey => $composableBuilder(
    column: $table.similarityKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get effectiveMinutes => $composableBuilder(
    column: $table.effectiveMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalXp =>
      $composableBuilder(column: $table.totalXp, builder: (column) => column);

  GeneratedColumn<bool> get trivial =>
      $composableBuilder(column: $table.trivial, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get proposalJson => $composableBuilder(
    column: $table.proposalJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get provisional => $composableBuilder(
    column: $table.provisional,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CompletionsTableAnnotationComposer get completionId {
    final $$CompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completionId,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvaluationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EvaluationsTable,
          EvaluationRow,
          $$EvaluationsTableFilterComposer,
          $$EvaluationsTableOrderingComposer,
          $$EvaluationsTableAnnotationComposer,
          $$EvaluationsTableCreateCompanionBuilder,
          $$EvaluationsTableUpdateCompanionBuilder,
          (EvaluationRow, $$EvaluationsTableReferences),
          EvaluationRow,
          PrefetchHooks Function({bool completionId})
        > {
  $$EvaluationsTableTableManager(_$AppDatabase db, $EvaluationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EvaluationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EvaluationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EvaluationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> completionId = const Value.absent(),
                Value<String> localDay = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> similarityKey = const Value.absent(),
                Value<int> effectiveMinutes = const Value.absent(),
                Value<int> totalXp = const Value.absent(),
                Value<bool> trivial = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> proposalJson = const Value.absent(),
                Value<String> resultJson = const Value.absent(),
                Value<bool> provisional = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EvaluationsCompanion(
                completionId: completionId,
                localDay: localDay,
                category: category,
                similarityKey: similarityKey,
                effectiveMinutes: effectiveMinutes,
                totalXp: totalXp,
                trivial: trivial,
                source: source,
                proposalJson: proposalJson,
                resultJson: resultJson,
                provisional: provisional,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String completionId,
                required String localDay,
                required String category,
                required String similarityKey,
                required int effectiveMinutes,
                required int totalXp,
                required bool trivial,
                required String source,
                required String proposalJson,
                required String resultJson,
                Value<bool> provisional = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => EvaluationsCompanion.insert(
                completionId: completionId,
                localDay: localDay,
                category: category,
                similarityKey: similarityKey,
                effectiveMinutes: effectiveMinutes,
                totalXp: totalXp,
                trivial: trivial,
                source: source,
                proposalJson: proposalJson,
                resultJson: resultJson,
                provisional: provisional,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EvaluationsTable, EvaluationRow>(table),
                  $$EvaluationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({completionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (completionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.completionId,
                        referencedTable: $$EvaluationsTableReferences
                            ._completionIdTable(db),
                        referencedColumn: $$EvaluationsTableReferences
                            ._completionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EvaluationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EvaluationsTable,
      EvaluationRow,
      $$EvaluationsTableFilterComposer,
      $$EvaluationsTableOrderingComposer,
      $$EvaluationsTableAnnotationComposer,
      $$EvaluationsTableCreateCompanionBuilder,
      $$EvaluationsTableUpdateCompanionBuilder,
      (EvaluationRow, $$EvaluationsTableReferences),
      EvaluationRow,
      PrefetchHooks Function({bool completionId})
    >;
typedef $$LedgerEntriesTableCreateCompanionBuilder =
    LedgerEntriesCompanion Function({
      required String id,
      Value<String?> completionId,
      required String attribute,
      required int amount,
      required int rawAmount,
      required String kind,
      required String ruleVersion,
      required String localDay,
      Value<bool> provisional,
      Value<bool> superseded,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LedgerEntriesTableUpdateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<String> id,
      Value<String?> completionId,
      Value<String> attribute,
      Value<int> amount,
      Value<int> rawAmount,
      Value<String> kind,
      Value<String> ruleVersion,
      Value<String> localDay,
      Value<bool> provisional,
      Value<bool> superseded,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completionId => $composableBuilder(
    column: $table.completionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attribute => $composableBuilder(
    column: $table.attribute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rawAmount => $composableBuilder(
    column: $table.rawAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDay => $composableBuilder(
    column: $table.localDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get provisional => $composableBuilder(
    column: $table.provisional,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get superseded => $composableBuilder(
    column: $table.superseded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completionId => $composableBuilder(
    column: $table.completionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attribute => $composableBuilder(
    column: $table.attribute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rawAmount => $composableBuilder(
    column: $table.rawAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDay => $composableBuilder(
    column: $table.localDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get provisional => $composableBuilder(
    column: $table.provisional,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get superseded => $composableBuilder(
    column: $table.superseded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get completionId => $composableBuilder(
    column: $table.completionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attribute =>
      $composableBuilder(column: $table.attribute, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get rawAmount =>
      $composableBuilder(column: $table.rawAmount, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localDay =>
      $composableBuilder(column: $table.localDay, builder: (column) => column);

  GeneratedColumn<bool> get provisional => $composableBuilder(
    column: $table.provisional,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get superseded => $composableBuilder(
    column: $table.superseded,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerEntriesTable,
          LedgerRow,
          $$LedgerEntriesTableFilterComposer,
          $$LedgerEntriesTableOrderingComposer,
          $$LedgerEntriesTableAnnotationComposer,
          $$LedgerEntriesTableCreateCompanionBuilder,
          $$LedgerEntriesTableUpdateCompanionBuilder,
          (
            LedgerRow,
            BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerRow>,
          ),
          LedgerRow,
          PrefetchHooks Function()
        > {
  $$LedgerEntriesTableTableManager(_$AppDatabase db, $LedgerEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> completionId = const Value.absent(),
                Value<String> attribute = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> rawAmount = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> ruleVersion = const Value.absent(),
                Value<String> localDay = const Value.absent(),
                Value<bool> provisional = const Value.absent(),
                Value<bool> superseded = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesCompanion(
                id: id,
                completionId: completionId,
                attribute: attribute,
                amount: amount,
                rawAmount: rawAmount,
                kind: kind,
                ruleVersion: ruleVersion,
                localDay: localDay,
                provisional: provisional,
                superseded: superseded,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> completionId = const Value.absent(),
                required String attribute,
                required int amount,
                required int rawAmount,
                required String kind,
                required String ruleVersion,
                required String localDay,
                Value<bool> provisional = const Value.absent(),
                Value<bool> superseded = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesCompanion.insert(
                id: id,
                completionId: completionId,
                attribute: attribute,
                amount: amount,
                rawAmount: rawAmount,
                kind: kind,
                ruleVersion: ruleVersion,
                localDay: localDay,
                provisional: provisional,
                superseded: superseded,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerEntriesTable, LedgerRow>(table),
                  BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerEntriesTable,
      LedgerRow,
      $$LedgerEntriesTableFilterComposer,
      $$LedgerEntriesTableOrderingComposer,
      $$LedgerEntriesTableAnnotationComposer,
      $$LedgerEntriesTableCreateCompanionBuilder,
      $$LedgerEntriesTableUpdateCompanionBuilder,
      (
        LedgerRow,
        BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerRow>,
      ),
      LedgerRow,
      PrefetchHooks Function()
    >;
typedef $$UnlockedAchievementsTableCreateCompanionBuilder =
    UnlockedAchievementsCompanion Function({
      required String id,
      required DateTime unlockedAt,
      Value<int> rowid,
    });
typedef $$UnlockedAchievementsTableUpdateCompanionBuilder =
    UnlockedAchievementsCompanion Function({
      Value<String> id,
      Value<DateTime> unlockedAt,
      Value<int> rowid,
    });

class $$UnlockedAchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $UnlockedAchievementsTable> {
  $$UnlockedAchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UnlockedAchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $UnlockedAchievementsTable> {
  $$UnlockedAchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnlockedAchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnlockedAchievementsTable> {
  $$UnlockedAchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => column,
  );
}

class $$UnlockedAchievementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnlockedAchievementsTable,
          AchievementRow,
          $$UnlockedAchievementsTableFilterComposer,
          $$UnlockedAchievementsTableOrderingComposer,
          $$UnlockedAchievementsTableAnnotationComposer,
          $$UnlockedAchievementsTableCreateCompanionBuilder,
          $$UnlockedAchievementsTableUpdateCompanionBuilder,
          (
            AchievementRow,
            BaseReferences<
              _$AppDatabase,
              $UnlockedAchievementsTable,
              AchievementRow
            >,
          ),
          AchievementRow,
          PrefetchHooks Function()
        > {
  $$UnlockedAchievementsTableTableManager(
    _$AppDatabase db,
    $UnlockedAchievementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnlockedAchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnlockedAchievementsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UnlockedAchievementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> unlockedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnlockedAchievementsCompanion(
                id: id,
                unlockedAt: unlockedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime unlockedAt,
                Value<int> rowid = const Value.absent(),
              }) => UnlockedAchievementsCompanion.insert(
                id: id,
                unlockedAt: unlockedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UnlockedAchievementsTable, AchievementRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $UnlockedAchievementsTable,
                    AchievementRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UnlockedAchievementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnlockedAchievementsTable,
      AchievementRow,
      $$UnlockedAchievementsTableFilterComposer,
      $$UnlockedAchievementsTableOrderingComposer,
      $$UnlockedAchievementsTableAnnotationComposer,
      $$UnlockedAchievementsTableCreateCompanionBuilder,
      $$UnlockedAchievementsTableUpdateCompanionBuilder,
      (
        AchievementRow,
        BaseReferences<
          _$AppDatabase,
          $UnlockedAchievementsTable,
          AchievementRow
        >,
      ),
      AchievementRow,
      PrefetchHooks Function()
    >;
typedef $$DayMarksTableCreateCompanionBuilder = DayMarksCompanion Function({
  required String localDay,
  Value<bool> rest,
  Value<bool> paused,
  Value<int> rowid,
});
typedef $$DayMarksTableUpdateCompanionBuilder = DayMarksCompanion Function({
  Value<String> localDay,
  Value<bool> rest,
  Value<bool> paused,
  Value<int> rowid,
});

class $$DayMarksTableFilterComposer
    extends Composer<_$AppDatabase, $DayMarksTable> {
  $$DayMarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localDay => $composableBuilder(
    column: $table.localDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rest => $composableBuilder(
    column: $table.rest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayMarksTableOrderingComposer
    extends Composer<_$AppDatabase, $DayMarksTable> {
  $$DayMarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localDay => $composableBuilder(
    column: $table.localDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rest => $composableBuilder(
    column: $table.rest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayMarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayMarksTable> {
  $$DayMarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localDay =>
      $composableBuilder(column: $table.localDay, builder: (column) => column);

  GeneratedColumn<bool> get rest =>
      $composableBuilder(column: $table.rest, builder: (column) => column);

  GeneratedColumn<bool> get paused =>
      $composableBuilder(column: $table.paused, builder: (column) => column);
}

class $$DayMarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayMarksTable,
          DayMarkRow,
          $$DayMarksTableFilterComposer,
          $$DayMarksTableOrderingComposer,
          $$DayMarksTableAnnotationComposer,
          $$DayMarksTableCreateCompanionBuilder,
          $$DayMarksTableUpdateCompanionBuilder,
          (
            DayMarkRow,
            BaseReferences<_$AppDatabase, $DayMarksTable, DayMarkRow>,
          ),
          DayMarkRow,
          PrefetchHooks Function()
        > {
  $$DayMarksTableTableManager(_$AppDatabase db, $DayMarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayMarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayMarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayMarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localDay = const Value.absent(),
                Value<bool> rest = const Value.absent(),
                Value<bool> paused = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayMarksCompanion(
                localDay: localDay,
                rest: rest,
                paused: paused,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localDay,
                Value<bool> rest = const Value.absent(),
                Value<bool> paused = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayMarksCompanion.insert(
                localDay: localDay,
                rest: rest,
                paused: paused,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DayMarksTable, DayMarkRow>(table),
                  BaseReferences<_$AppDatabase, $DayMarksTable, DayMarkRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayMarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayMarksTable,
      DayMarkRow,
      $$DayMarksTableFilterComposer,
      $$DayMarksTableOrderingComposer,
      $$DayMarksTableAnnotationComposer,
      $$DayMarksTableCreateCompanionBuilder,
      $$DayMarksTableUpdateCompanionBuilder,
      (DayMarkRow, BaseReferences<_$AppDatabase, $DayMarksTable, DayMarkRow>),
      DayMarkRow,
      PrefetchHooks Function()
    >;
typedef $$KeyValuesTableCreateCompanionBuilder = KeyValuesCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KeyValuesTableUpdateCompanionBuilder = KeyValuesCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValuesTable,
          KeyValueRow,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (
            KeyValueRow,
            BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValueRow>,
          ),
          KeyValueRow,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValuesTable, KeyValueRow>(table),
                  BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValueRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValuesTable,
      KeyValueRow,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (
        KeyValueRow,
        BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValueRow>,
      ),
      KeyValueRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxEntriesTableCreateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<int> id,
      required String entity,
      required String entityId,
      required String op,
      required String payload,
      Value<int> attempts,
      required DateTime createdAt,
    });
typedef $$OutboxEntriesTableUpdateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<int> id,
      Value<String> entity,
      Value<String> entityId,
      Value<String> op,
      Value<String> payload,
      Value<int> attempts,
      Value<DateTime> createdAt,
    });

class $$OutboxEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxEntriesTable,
          OutboxRow,
          $$OutboxEntriesTableFilterComposer,
          $$OutboxEntriesTableOrderingComposer,
          $$OutboxEntriesTableAnnotationComposer,
          $$OutboxEntriesTableCreateCompanionBuilder,
          $$OutboxEntriesTableUpdateCompanionBuilder,
          (
            OutboxRow,
            BaseReferences<_$AppDatabase, $OutboxEntriesTable, OutboxRow>,
          ),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxEntriesTableTableManager(_$AppDatabase db, $OutboxEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxEntriesCompanion(
                id: id,
                entity: entity,
                entityId: entityId,
                op: op,
                payload: payload,
                attempts: attempts,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entity,
                required String entityId,
                required String op,
                required String payload,
                Value<int> attempts = const Value.absent(),
                required DateTime createdAt,
              }) => OutboxEntriesCompanion.insert(
                id: id,
                entity: entity,
                entityId: entityId,
                op: op,
                payload: payload,
                attempts: attempts,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxEntriesTable, OutboxRow>(table),
                  BaseReferences<_$AppDatabase, $OutboxEntriesTable, OutboxRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxEntriesTable,
      OutboxRow,
      $$OutboxEntriesTableFilterComposer,
      $$OutboxEntriesTableOrderingComposer,
      $$OutboxEntriesTableAnnotationComposer,
      $$OutboxEntriesTableCreateCompanionBuilder,
      $$OutboxEntriesTableUpdateCompanionBuilder,
      (
        OutboxRow,
        BaseReferences<_$AppDatabase, $OutboxEntriesTable, OutboxRow>,
      ),
      OutboxRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$QuestsTableTableManager get quests =>
      $$QuestsTableTableManager(_db, _db.quests);
  $$SubtasksTableTableManager get subtasks =>
      $$SubtasksTableTableManager(_db, _db.subtasks);
  $$CompletionsTableTableManager get completions =>
      $$CompletionsTableTableManager(_db, _db.completions);
  $$EvaluationsTableTableManager get evaluations =>
      $$EvaluationsTableTableManager(_db, _db.evaluations);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db, _db.ledgerEntries);
  $$UnlockedAchievementsTableTableManager get unlockedAchievements =>
      $$UnlockedAchievementsTableTableManager(_db, _db.unlockedAchievements);
  $$DayMarksTableTableManager get dayMarks =>
      $$DayMarksTableTableManager(_db, _db.dayMarks);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
}
