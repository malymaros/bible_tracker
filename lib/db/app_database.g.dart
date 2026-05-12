// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ReadChaptersTable extends ReadChapters
    with TableInfo<$ReadChaptersTable, ReadChapterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterNumberMeta = const VerificationMeta(
    'chapterNumber',
  );
  @override
  late final GeneratedColumn<int> chapterNumber = GeneratedColumn<int>(
    'chapter_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<int> readAt = GeneratedColumn<int>(
    'read_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [bookId, chapterNumber, readAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'read_chapters';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadChapterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter_number')) {
      context.handle(
        _chapterNumberMeta,
        chapterNumber.isAcceptableOrUnknown(
          data['chapter_number']!,
          _chapterNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chapterNumberMeta);
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    } else if (isInserting) {
      context.missing(_readAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId, chapterNumber};
  @override
  ReadChapterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadChapterRow(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      chapterNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_number'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}read_at'],
      )!,
    );
  }

  @override
  $ReadChaptersTable createAlias(String alias) {
    return $ReadChaptersTable(attachedDatabase, alias);
  }
}

class ReadChapterRow extends DataClass implements Insertable<ReadChapterRow> {
  final String bookId;
  final int chapterNumber;
  final int readAt;
  const ReadChapterRow({
    required this.bookId,
    required this.chapterNumber,
    required this.readAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<String>(bookId);
    map['chapter_number'] = Variable<int>(chapterNumber);
    map['read_at'] = Variable<int>(readAt);
    return map;
  }

  ReadChaptersCompanion toCompanion(bool nullToAbsent) {
    return ReadChaptersCompanion(
      bookId: Value(bookId),
      chapterNumber: Value(chapterNumber),
      readAt: Value(readAt),
    );
  }

  factory ReadChapterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadChapterRow(
      bookId: serializer.fromJson<String>(json['bookId']),
      chapterNumber: serializer.fromJson<int>(json['chapterNumber']),
      readAt: serializer.fromJson<int>(json['readAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<String>(bookId),
      'chapterNumber': serializer.toJson<int>(chapterNumber),
      'readAt': serializer.toJson<int>(readAt),
    };
  }

  ReadChapterRow copyWith({String? bookId, int? chapterNumber, int? readAt}) =>
      ReadChapterRow(
        bookId: bookId ?? this.bookId,
        chapterNumber: chapterNumber ?? this.chapterNumber,
        readAt: readAt ?? this.readAt,
      );
  ReadChapterRow copyWithCompanion(ReadChaptersCompanion data) {
    return ReadChapterRow(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterNumber: data.chapterNumber.present
          ? data.chapterNumber.value
          : this.chapterNumber,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadChapterRow(')
          ..write('bookId: $bookId, ')
          ..write('chapterNumber: $chapterNumber, ')
          ..write('readAt: $readAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bookId, chapterNumber, readAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadChapterRow &&
          other.bookId == this.bookId &&
          other.chapterNumber == this.chapterNumber &&
          other.readAt == this.readAt);
}

class ReadChaptersCompanion extends UpdateCompanion<ReadChapterRow> {
  final Value<String> bookId;
  final Value<int> chapterNumber;
  final Value<int> readAt;
  final Value<int> rowid;
  const ReadChaptersCompanion({
    this.bookId = const Value.absent(),
    this.chapterNumber = const Value.absent(),
    this.readAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadChaptersCompanion.insert({
    required String bookId,
    required int chapterNumber,
    required int readAt,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       chapterNumber = Value(chapterNumber),
       readAt = Value(readAt);
  static Insertable<ReadChapterRow> custom({
    Expression<String>? bookId,
    Expression<int>? chapterNumber,
    Expression<int>? readAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (chapterNumber != null) 'chapter_number': chapterNumber,
      if (readAt != null) 'read_at': readAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadChaptersCompanion copyWith({
    Value<String>? bookId,
    Value<int>? chapterNumber,
    Value<int>? readAt,
    Value<int>? rowid,
  }) {
    return ReadChaptersCompanion(
      bookId: bookId ?? this.bookId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      readAt: readAt ?? this.readAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (chapterNumber.present) {
      map['chapter_number'] = Variable<int>(chapterNumber.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<int>(readAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadChaptersCompanion(')
          ..write('bookId: $bookId, ')
          ..write('chapterNumber: $chapterNumber, ')
          ..write('readAt: $readAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingPlansTable extends ReadingPlans
    with TableInfo<$ReadingPlansTable, ReadingPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<int> startDate = GeneratedColumn<int>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalDaysMeta = const VerificationMeta(
    'totalDays',
  );
  @override
  late final GeneratedColumn<int> totalDays = GeneratedColumn<int>(
    'total_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedBookIdsMeta = const VerificationMeta(
    'selectedBookIds',
  );
  @override
  late final GeneratedColumn<String> selectedBookIds = GeneratedColumn<String>(
    'selected_book_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startDate,
    totalDays,
    selectedBookIds,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('total_days')) {
      context.handle(
        _totalDaysMeta,
        totalDays.isAcceptableOrUnknown(data['total_days']!, _totalDaysMeta),
      );
    } else if (isInserting) {
      context.missing(_totalDaysMeta);
    }
    if (data.containsKey('selected_book_ids')) {
      context.handle(
        _selectedBookIdsMeta,
        selectedBookIds.isAcceptableOrUnknown(
          data['selected_book_ids']!,
          _selectedBookIdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_selectedBookIdsMeta);
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
  ReadingPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_date'],
      )!,
      totalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_days'],
      )!,
      selectedBookIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_book_ids'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReadingPlansTable createAlias(String alias) {
    return $ReadingPlansTable(attachedDatabase, alias);
  }
}

class ReadingPlanRow extends DataClass implements Insertable<ReadingPlanRow> {
  final String id;
  final int startDate;
  final int totalDays;
  final String selectedBookIds;
  final int createdAt;
  const ReadingPlanRow({
    required this.id,
    required this.startDate,
    required this.totalDays,
    required this.selectedBookIds,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['start_date'] = Variable<int>(startDate);
    map['total_days'] = Variable<int>(totalDays);
    map['selected_book_ids'] = Variable<String>(selectedBookIds);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ReadingPlansCompanion toCompanion(bool nullToAbsent) {
    return ReadingPlansCompanion(
      id: Value(id),
      startDate: Value(startDate),
      totalDays: Value(totalDays),
      selectedBookIds: Value(selectedBookIds),
      createdAt: Value(createdAt),
    );
  }

  factory ReadingPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingPlanRow(
      id: serializer.fromJson<String>(json['id']),
      startDate: serializer.fromJson<int>(json['startDate']),
      totalDays: serializer.fromJson<int>(json['totalDays']),
      selectedBookIds: serializer.fromJson<String>(json['selectedBookIds']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startDate': serializer.toJson<int>(startDate),
      'totalDays': serializer.toJson<int>(totalDays),
      'selectedBookIds': serializer.toJson<String>(selectedBookIds),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ReadingPlanRow copyWith({
    String? id,
    int? startDate,
    int? totalDays,
    String? selectedBookIds,
    int? createdAt,
  }) => ReadingPlanRow(
    id: id ?? this.id,
    startDate: startDate ?? this.startDate,
    totalDays: totalDays ?? this.totalDays,
    selectedBookIds: selectedBookIds ?? this.selectedBookIds,
    createdAt: createdAt ?? this.createdAt,
  );
  ReadingPlanRow copyWithCompanion(ReadingPlansCompanion data) {
    return ReadingPlanRow(
      id: data.id.present ? data.id.value : this.id,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      totalDays: data.totalDays.present ? data.totalDays.value : this.totalDays,
      selectedBookIds: data.selectedBookIds.present
          ? data.selectedBookIds.value
          : this.selectedBookIds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingPlanRow(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('totalDays: $totalDays, ')
          ..write('selectedBookIds: $selectedBookIds, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startDate, totalDays, selectedBookIds, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingPlanRow &&
          other.id == this.id &&
          other.startDate == this.startDate &&
          other.totalDays == this.totalDays &&
          other.selectedBookIds == this.selectedBookIds &&
          other.createdAt == this.createdAt);
}

class ReadingPlansCompanion extends UpdateCompanion<ReadingPlanRow> {
  final Value<String> id;
  final Value<int> startDate;
  final Value<int> totalDays;
  final Value<String> selectedBookIds;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ReadingPlansCompanion({
    this.id = const Value.absent(),
    this.startDate = const Value.absent(),
    this.totalDays = const Value.absent(),
    this.selectedBookIds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingPlansCompanion.insert({
    required String id,
    required int startDate,
    required int totalDays,
    required String selectedBookIds,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startDate = Value(startDate),
       totalDays = Value(totalDays),
       selectedBookIds = Value(selectedBookIds),
       createdAt = Value(createdAt);
  static Insertable<ReadingPlanRow> custom({
    Expression<String>? id,
    Expression<int>? startDate,
    Expression<int>? totalDays,
    Expression<String>? selectedBookIds,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startDate != null) 'start_date': startDate,
      if (totalDays != null) 'total_days': totalDays,
      if (selectedBookIds != null) 'selected_book_ids': selectedBookIds,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingPlansCompanion copyWith({
    Value<String>? id,
    Value<int>? startDate,
    Value<int>? totalDays,
    Value<String>? selectedBookIds,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return ReadingPlansCompanion(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      totalDays: totalDays ?? this.totalDays,
      selectedBookIds: selectedBookIds ?? this.selectedBookIds,
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
    if (startDate.present) {
      map['start_date'] = Variable<int>(startDate.value);
    }
    if (totalDays.present) {
      map['total_days'] = Variable<int>(totalDays.value);
    }
    if (selectedBookIds.present) {
      map['selected_book_ids'] = Variable<String>(selectedBookIds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingPlansCompanion(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('totalDays: $totalDays, ')
          ..write('selectedBookIds: $selectedBookIds, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanDaysTable extends PlanDays
    with TableInfo<$PlanDaysTable, PlanDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayNumberMeta = const VerificationMeta(
    'dayNumber',
  );
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
    'day_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<int> scheduledDate = GeneratedColumn<int>(
    'scheduled_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chaptersJsonMeta = const VerificationMeta(
    'chaptersJson',
  );
  @override
  late final GeneratedColumn<String> chaptersJson = GeneratedColumn<String>(
    'chapters_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    planId,
    dayNumber,
    scheduledDate,
    chaptersJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(
        _dayNumberMeta,
        dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_dayNumberMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    if (data.containsKey('chapters_json')) {
      context.handle(
        _chaptersJsonMeta,
        chaptersJson.isAcceptableOrUnknown(
          data['chapters_json']!,
          _chaptersJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chaptersJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {planId, dayNumber};
  @override
  PlanDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanDayRow(
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      dayNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_number'],
      )!,
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scheduled_date'],
      )!,
      chaptersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapters_json'],
      )!,
    );
  }

  @override
  $PlanDaysTable createAlias(String alias) {
    return $PlanDaysTable(attachedDatabase, alias);
  }
}

class PlanDayRow extends DataClass implements Insertable<PlanDayRow> {
  final String planId;
  final int dayNumber;
  final int scheduledDate;
  final String chaptersJson;
  const PlanDayRow({
    required this.planId,
    required this.dayNumber,
    required this.scheduledDate,
    required this.chaptersJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['plan_id'] = Variable<String>(planId);
    map['day_number'] = Variable<int>(dayNumber);
    map['scheduled_date'] = Variable<int>(scheduledDate);
    map['chapters_json'] = Variable<String>(chaptersJson);
    return map;
  }

  PlanDaysCompanion toCompanion(bool nullToAbsent) {
    return PlanDaysCompanion(
      planId: Value(planId),
      dayNumber: Value(dayNumber),
      scheduledDate: Value(scheduledDate),
      chaptersJson: Value(chaptersJson),
    );
  }

  factory PlanDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanDayRow(
      planId: serializer.fromJson<String>(json['planId']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      scheduledDate: serializer.fromJson<int>(json['scheduledDate']),
      chaptersJson: serializer.fromJson<String>(json['chaptersJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'planId': serializer.toJson<String>(planId),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'scheduledDate': serializer.toJson<int>(scheduledDate),
      'chaptersJson': serializer.toJson<String>(chaptersJson),
    };
  }

  PlanDayRow copyWith({
    String? planId,
    int? dayNumber,
    int? scheduledDate,
    String? chaptersJson,
  }) => PlanDayRow(
    planId: planId ?? this.planId,
    dayNumber: dayNumber ?? this.dayNumber,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    chaptersJson: chaptersJson ?? this.chaptersJson,
  );
  PlanDayRow copyWithCompanion(PlanDaysCompanion data) {
    return PlanDayRow(
      planId: data.planId.present ? data.planId.value : this.planId,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      chaptersJson: data.chaptersJson.present
          ? data.chaptersJson.value
          : this.chaptersJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanDayRow(')
          ..write('planId: $planId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('chaptersJson: $chaptersJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(planId, dayNumber, scheduledDate, chaptersJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanDayRow &&
          other.planId == this.planId &&
          other.dayNumber == this.dayNumber &&
          other.scheduledDate == this.scheduledDate &&
          other.chaptersJson == this.chaptersJson);
}

class PlanDaysCompanion extends UpdateCompanion<PlanDayRow> {
  final Value<String> planId;
  final Value<int> dayNumber;
  final Value<int> scheduledDate;
  final Value<String> chaptersJson;
  final Value<int> rowid;
  const PlanDaysCompanion({
    this.planId = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.chaptersJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanDaysCompanion.insert({
    required String planId,
    required int dayNumber,
    required int scheduledDate,
    required String chaptersJson,
    this.rowid = const Value.absent(),
  }) : planId = Value(planId),
       dayNumber = Value(dayNumber),
       scheduledDate = Value(scheduledDate),
       chaptersJson = Value(chaptersJson);
  static Insertable<PlanDayRow> custom({
    Expression<String>? planId,
    Expression<int>? dayNumber,
    Expression<int>? scheduledDate,
    Expression<String>? chaptersJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (planId != null) 'plan_id': planId,
      if (dayNumber != null) 'day_number': dayNumber,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (chaptersJson != null) 'chapters_json': chaptersJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanDaysCompanion copyWith({
    Value<String>? planId,
    Value<int>? dayNumber,
    Value<int>? scheduledDate,
    Value<String>? chaptersJson,
    Value<int>? rowid,
  }) {
    return PlanDaysCompanion(
      planId: planId ?? this.planId,
      dayNumber: dayNumber ?? this.dayNumber,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      chaptersJson: chaptersJson ?? this.chaptersJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<int>(scheduledDate.value);
    }
    if (chaptersJson.present) {
      map['chapters_json'] = Variable<String>(chaptersJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanDaysCompanion(')
          ..write('planId: $planId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('chaptersJson: $chaptersJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChapterTextsTable extends ChapterTexts
    with TableInfo<$ChapterTextsTable, ChapterTextRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChapterTextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterNumberMeta = const VerificationMeta(
    'chapterNumber',
  );
  @override
  late final GeneratedColumn<int> chapterNumber = GeneratedColumn<int>(
    'chapter_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _htmlContentMeta = const VerificationMeta(
    'htmlContent',
  );
  @override
  late final GeneratedColumn<String> htmlContent = GeneratedColumn<String>(
    'html_content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plainTextMeta = const VerificationMeta(
    'plainText',
  );
  @override
  late final GeneratedColumn<String> plainText = GeneratedColumn<String>(
    'plain_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parserVersionMeta = const VerificationMeta(
    'parserVersion',
  );
  @override
  late final GeneratedColumn<int> parserVersion = GeneratedColumn<int>(
    'parser_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    chapterNumber,
    htmlContent,
    plainText,
    sourceUrl,
    parserVersion,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapter_texts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChapterTextRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter_number')) {
      context.handle(
        _chapterNumberMeta,
        chapterNumber.isAcceptableOrUnknown(
          data['chapter_number']!,
          _chapterNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chapterNumberMeta);
    }
    if (data.containsKey('html_content')) {
      context.handle(
        _htmlContentMeta,
        htmlContent.isAcceptableOrUnknown(
          data['html_content']!,
          _htmlContentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_htmlContentMeta);
    }
    if (data.containsKey('plain_text')) {
      context.handle(
        _plainTextMeta,
        plainText.isAcceptableOrUnknown(data['plain_text']!, _plainTextMeta),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceUrlMeta);
    }
    if (data.containsKey('parser_version')) {
      context.handle(
        _parserVersionMeta,
        parserVersion.isAcceptableOrUnknown(
          data['parser_version']!,
          _parserVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parserVersionMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId, chapterNumber};
  @override
  ChapterTextRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChapterTextRow(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      chapterNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_number'],
      )!,
      htmlContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}html_content'],
      )!,
      plainText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plain_text'],
      ),
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      )!,
      parserVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parser_version'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $ChapterTextsTable createAlias(String alias) {
    return $ChapterTextsTable(attachedDatabase, alias);
  }
}

class ChapterTextRow extends DataClass implements Insertable<ChapterTextRow> {
  final String bookId;
  final int chapterNumber;
  final String htmlContent;
  final String? plainText;
  final String sourceUrl;
  final int parserVersion;
  final int cachedAt;
  const ChapterTextRow({
    required this.bookId,
    required this.chapterNumber,
    required this.htmlContent,
    this.plainText,
    required this.sourceUrl,
    required this.parserVersion,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<String>(bookId);
    map['chapter_number'] = Variable<int>(chapterNumber);
    map['html_content'] = Variable<String>(htmlContent);
    if (!nullToAbsent || plainText != null) {
      map['plain_text'] = Variable<String>(plainText);
    }
    map['source_url'] = Variable<String>(sourceUrl);
    map['parser_version'] = Variable<int>(parserVersion);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  ChapterTextsCompanion toCompanion(bool nullToAbsent) {
    return ChapterTextsCompanion(
      bookId: Value(bookId),
      chapterNumber: Value(chapterNumber),
      htmlContent: Value(htmlContent),
      plainText: plainText == null && nullToAbsent
          ? const Value.absent()
          : Value(plainText),
      sourceUrl: Value(sourceUrl),
      parserVersion: Value(parserVersion),
      cachedAt: Value(cachedAt),
    );
  }

  factory ChapterTextRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChapterTextRow(
      bookId: serializer.fromJson<String>(json['bookId']),
      chapterNumber: serializer.fromJson<int>(json['chapterNumber']),
      htmlContent: serializer.fromJson<String>(json['htmlContent']),
      plainText: serializer.fromJson<String?>(json['plainText']),
      sourceUrl: serializer.fromJson<String>(json['sourceUrl']),
      parserVersion: serializer.fromJson<int>(json['parserVersion']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<String>(bookId),
      'chapterNumber': serializer.toJson<int>(chapterNumber),
      'htmlContent': serializer.toJson<String>(htmlContent),
      'plainText': serializer.toJson<String?>(plainText),
      'sourceUrl': serializer.toJson<String>(sourceUrl),
      'parserVersion': serializer.toJson<int>(parserVersion),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  ChapterTextRow copyWith({
    String? bookId,
    int? chapterNumber,
    String? htmlContent,
    Value<String?> plainText = const Value.absent(),
    String? sourceUrl,
    int? parserVersion,
    int? cachedAt,
  }) => ChapterTextRow(
    bookId: bookId ?? this.bookId,
    chapterNumber: chapterNumber ?? this.chapterNumber,
    htmlContent: htmlContent ?? this.htmlContent,
    plainText: plainText.present ? plainText.value : this.plainText,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    parserVersion: parserVersion ?? this.parserVersion,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  ChapterTextRow copyWithCompanion(ChapterTextsCompanion data) {
    return ChapterTextRow(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterNumber: data.chapterNumber.present
          ? data.chapterNumber.value
          : this.chapterNumber,
      htmlContent: data.htmlContent.present
          ? data.htmlContent.value
          : this.htmlContent,
      plainText: data.plainText.present ? data.plainText.value : this.plainText,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      parserVersion: data.parserVersion.present
          ? data.parserVersion.value
          : this.parserVersion,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChapterTextRow(')
          ..write('bookId: $bookId, ')
          ..write('chapterNumber: $chapterNumber, ')
          ..write('htmlContent: $htmlContent, ')
          ..write('plainText: $plainText, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('parserVersion: $parserVersion, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bookId,
    chapterNumber,
    htmlContent,
    plainText,
    sourceUrl,
    parserVersion,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChapterTextRow &&
          other.bookId == this.bookId &&
          other.chapterNumber == this.chapterNumber &&
          other.htmlContent == this.htmlContent &&
          other.plainText == this.plainText &&
          other.sourceUrl == this.sourceUrl &&
          other.parserVersion == this.parserVersion &&
          other.cachedAt == this.cachedAt);
}

class ChapterTextsCompanion extends UpdateCompanion<ChapterTextRow> {
  final Value<String> bookId;
  final Value<int> chapterNumber;
  final Value<String> htmlContent;
  final Value<String?> plainText;
  final Value<String> sourceUrl;
  final Value<int> parserVersion;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const ChapterTextsCompanion({
    this.bookId = const Value.absent(),
    this.chapterNumber = const Value.absent(),
    this.htmlContent = const Value.absent(),
    this.plainText = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.parserVersion = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChapterTextsCompanion.insert({
    required String bookId,
    required int chapterNumber,
    required String htmlContent,
    this.plainText = const Value.absent(),
    required String sourceUrl,
    required int parserVersion,
    required int cachedAt,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       chapterNumber = Value(chapterNumber),
       htmlContent = Value(htmlContent),
       sourceUrl = Value(sourceUrl),
       parserVersion = Value(parserVersion),
       cachedAt = Value(cachedAt);
  static Insertable<ChapterTextRow> custom({
    Expression<String>? bookId,
    Expression<int>? chapterNumber,
    Expression<String>? htmlContent,
    Expression<String>? plainText,
    Expression<String>? sourceUrl,
    Expression<int>? parserVersion,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (chapterNumber != null) 'chapter_number': chapterNumber,
      if (htmlContent != null) 'html_content': htmlContent,
      if (plainText != null) 'plain_text': plainText,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (parserVersion != null) 'parser_version': parserVersion,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChapterTextsCompanion copyWith({
    Value<String>? bookId,
    Value<int>? chapterNumber,
    Value<String>? htmlContent,
    Value<String?>? plainText,
    Value<String>? sourceUrl,
    Value<int>? parserVersion,
    Value<int>? cachedAt,
    Value<int>? rowid,
  }) {
    return ChapterTextsCompanion(
      bookId: bookId ?? this.bookId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      htmlContent: htmlContent ?? this.htmlContent,
      plainText: plainText ?? this.plainText,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      parserVersion: parserVersion ?? this.parserVersion,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (chapterNumber.present) {
      map['chapter_number'] = Variable<int>(chapterNumber.value);
    }
    if (htmlContent.present) {
      map['html_content'] = Variable<String>(htmlContent.value);
    }
    if (plainText.present) {
      map['plain_text'] = Variable<String>(plainText.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (parserVersion.present) {
      map['parser_version'] = Variable<int>(parserVersion.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChapterTextsCompanion(')
          ..write('bookId: $bookId, ')
          ..write('chapterNumber: $chapterNumber, ')
          ..write('htmlContent: $htmlContent, ')
          ..write('plainText: $plainText, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('parserVersion: $parserVersion, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReadChaptersTable readChapters = $ReadChaptersTable(this);
  late final $ReadingPlansTable readingPlans = $ReadingPlansTable(this);
  late final $PlanDaysTable planDays = $PlanDaysTable(this);
  late final $ChapterTextsTable chapterTexts = $ChapterTextsTable(this);
  late final ProgressDao progressDao = ProgressDao(this as AppDatabase);
  late final PlanDao planDao = PlanDao(this as AppDatabase);
  late final ChapterTextDao chapterTextDao = ChapterTextDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    readChapters,
    readingPlans,
    planDays,
    chapterTexts,
  ];
}

typedef $$ReadChaptersTableCreateCompanionBuilder =
    ReadChaptersCompanion Function({
      required String bookId,
      required int chapterNumber,
      required int readAt,
      Value<int> rowid,
    });
typedef $$ReadChaptersTableUpdateCompanionBuilder =
    ReadChaptersCompanion Function({
      Value<String> bookId,
      Value<int> chapterNumber,
      Value<int> readAt,
      Value<int> rowid,
    });

class $$ReadChaptersTableFilterComposer
    extends Composer<_$AppDatabase, $ReadChaptersTable> {
  $$ReadChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterNumber => $composableBuilder(
    column: $table.chapterNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadChaptersTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadChaptersTable> {
  $$ReadChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterNumber => $composableBuilder(
    column: $table.chapterNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadChaptersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadChaptersTable> {
  $$ReadChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<int> get chapterNumber => $composableBuilder(
    column: $table.chapterNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);
}

class $$ReadChaptersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadChaptersTable,
          ReadChapterRow,
          $$ReadChaptersTableFilterComposer,
          $$ReadChaptersTableOrderingComposer,
          $$ReadChaptersTableAnnotationComposer,
          $$ReadChaptersTableCreateCompanionBuilder,
          $$ReadChaptersTableUpdateCompanionBuilder,
          (
            ReadChapterRow,
            BaseReferences<_$AppDatabase, $ReadChaptersTable, ReadChapterRow>,
          ),
          ReadChapterRow,
          PrefetchHooks Function()
        > {
  $$ReadChaptersTableTableManager(_$AppDatabase db, $ReadChaptersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bookId = const Value.absent(),
                Value<int> chapterNumber = const Value.absent(),
                Value<int> readAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadChaptersCompanion(
                bookId: bookId,
                chapterNumber: chapterNumber,
                readAt: readAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookId,
                required int chapterNumber,
                required int readAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadChaptersCompanion.insert(
                bookId: bookId,
                chapterNumber: chapterNumber,
                readAt: readAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadChaptersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadChaptersTable,
      ReadChapterRow,
      $$ReadChaptersTableFilterComposer,
      $$ReadChaptersTableOrderingComposer,
      $$ReadChaptersTableAnnotationComposer,
      $$ReadChaptersTableCreateCompanionBuilder,
      $$ReadChaptersTableUpdateCompanionBuilder,
      (
        ReadChapterRow,
        BaseReferences<_$AppDatabase, $ReadChaptersTable, ReadChapterRow>,
      ),
      ReadChapterRow,
      PrefetchHooks Function()
    >;
typedef $$ReadingPlansTableCreateCompanionBuilder =
    ReadingPlansCompanion Function({
      required String id,
      required int startDate,
      required int totalDays,
      required String selectedBookIds,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$ReadingPlansTableUpdateCompanionBuilder =
    ReadingPlansCompanion Function({
      Value<String> id,
      Value<int> startDate,
      Value<int> totalDays,
      Value<String> selectedBookIds,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$ReadingPlansTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingPlansTable> {
  $$ReadingPlansTableFilterComposer({
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

  ColumnFilters<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDays => $composableBuilder(
    column: $table.totalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedBookIds => $composableBuilder(
    column: $table.selectedBookIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingPlansTable> {
  $$ReadingPlansTableOrderingComposer({
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

  ColumnOrderings<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDays => $composableBuilder(
    column: $table.totalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedBookIds => $composableBuilder(
    column: $table.selectedBookIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingPlansTable> {
  $$ReadingPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get totalDays =>
      $composableBuilder(column: $table.totalDays, builder: (column) => column);

  GeneratedColumn<String> get selectedBookIds => $composableBuilder(
    column: $table.selectedBookIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReadingPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingPlansTable,
          ReadingPlanRow,
          $$ReadingPlansTableFilterComposer,
          $$ReadingPlansTableOrderingComposer,
          $$ReadingPlansTableAnnotationComposer,
          $$ReadingPlansTableCreateCompanionBuilder,
          $$ReadingPlansTableUpdateCompanionBuilder,
          (
            ReadingPlanRow,
            BaseReferences<_$AppDatabase, $ReadingPlansTable, ReadingPlanRow>,
          ),
          ReadingPlanRow,
          PrefetchHooks Function()
        > {
  $$ReadingPlansTableTableManager(_$AppDatabase db, $ReadingPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> startDate = const Value.absent(),
                Value<int> totalDays = const Value.absent(),
                Value<String> selectedBookIds = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingPlansCompanion(
                id: id,
                startDate: startDate,
                totalDays: totalDays,
                selectedBookIds: selectedBookIds,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int startDate,
                required int totalDays,
                required String selectedBookIds,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingPlansCompanion.insert(
                id: id,
                startDate: startDate,
                totalDays: totalDays,
                selectedBookIds: selectedBookIds,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingPlansTable,
      ReadingPlanRow,
      $$ReadingPlansTableFilterComposer,
      $$ReadingPlansTableOrderingComposer,
      $$ReadingPlansTableAnnotationComposer,
      $$ReadingPlansTableCreateCompanionBuilder,
      $$ReadingPlansTableUpdateCompanionBuilder,
      (
        ReadingPlanRow,
        BaseReferences<_$AppDatabase, $ReadingPlansTable, ReadingPlanRow>,
      ),
      ReadingPlanRow,
      PrefetchHooks Function()
    >;
typedef $$PlanDaysTableCreateCompanionBuilder =
    PlanDaysCompanion Function({
      required String planId,
      required int dayNumber,
      required int scheduledDate,
      required String chaptersJson,
      Value<int> rowid,
    });
typedef $$PlanDaysTableUpdateCompanionBuilder =
    PlanDaysCompanion Function({
      Value<String> planId,
      Value<int> dayNumber,
      Value<int> scheduledDate,
      Value<String> chaptersJson,
      Value<int> rowid,
    });

class $$PlanDaysTableFilterComposer
    extends Composer<_$AppDatabase, $PlanDaysTable> {
  $$PlanDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chaptersJson => $composableBuilder(
    column: $table.chaptersJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanDaysTable> {
  $$PlanDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chaptersJson => $composableBuilder(
    column: $table.chaptersJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanDaysTable> {
  $$PlanDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<int> get dayNumber =>
      $composableBuilder(column: $table.dayNumber, builder: (column) => column);

  GeneratedColumn<int> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chaptersJson => $composableBuilder(
    column: $table.chaptersJson,
    builder: (column) => column,
  );
}

class $$PlanDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanDaysTable,
          PlanDayRow,
          $$PlanDaysTableFilterComposer,
          $$PlanDaysTableOrderingComposer,
          $$PlanDaysTableAnnotationComposer,
          $$PlanDaysTableCreateCompanionBuilder,
          $$PlanDaysTableUpdateCompanionBuilder,
          (
            PlanDayRow,
            BaseReferences<_$AppDatabase, $PlanDaysTable, PlanDayRow>,
          ),
          PlanDayRow,
          PrefetchHooks Function()
        > {
  $$PlanDaysTableTableManager(_$AppDatabase db, $PlanDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> planId = const Value.absent(),
                Value<int> dayNumber = const Value.absent(),
                Value<int> scheduledDate = const Value.absent(),
                Value<String> chaptersJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanDaysCompanion(
                planId: planId,
                dayNumber: dayNumber,
                scheduledDate: scheduledDate,
                chaptersJson: chaptersJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String planId,
                required int dayNumber,
                required int scheduledDate,
                required String chaptersJson,
                Value<int> rowid = const Value.absent(),
              }) => PlanDaysCompanion.insert(
                planId: planId,
                dayNumber: dayNumber,
                scheduledDate: scheduledDate,
                chaptersJson: chaptersJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlanDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanDaysTable,
      PlanDayRow,
      $$PlanDaysTableFilterComposer,
      $$PlanDaysTableOrderingComposer,
      $$PlanDaysTableAnnotationComposer,
      $$PlanDaysTableCreateCompanionBuilder,
      $$PlanDaysTableUpdateCompanionBuilder,
      (PlanDayRow, BaseReferences<_$AppDatabase, $PlanDaysTable, PlanDayRow>),
      PlanDayRow,
      PrefetchHooks Function()
    >;
typedef $$ChapterTextsTableCreateCompanionBuilder =
    ChapterTextsCompanion Function({
      required String bookId,
      required int chapterNumber,
      required String htmlContent,
      Value<String?> plainText,
      required String sourceUrl,
      required int parserVersion,
      required int cachedAt,
      Value<int> rowid,
    });
typedef $$ChapterTextsTableUpdateCompanionBuilder =
    ChapterTextsCompanion Function({
      Value<String> bookId,
      Value<int> chapterNumber,
      Value<String> htmlContent,
      Value<String?> plainText,
      Value<String> sourceUrl,
      Value<int> parserVersion,
      Value<int> cachedAt,
      Value<int> rowid,
    });

class $$ChapterTextsTableFilterComposer
    extends Composer<_$AppDatabase, $ChapterTextsTable> {
  $$ChapterTextsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterNumber => $composableBuilder(
    column: $table.chapterNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get htmlContent => $composableBuilder(
    column: $table.htmlContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plainText => $composableBuilder(
    column: $table.plainText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChapterTextsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChapterTextsTable> {
  $$ChapterTextsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterNumber => $composableBuilder(
    column: $table.chapterNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get htmlContent => $composableBuilder(
    column: $table.htmlContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plainText => $composableBuilder(
    column: $table.plainText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChapterTextsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChapterTextsTable> {
  $$ChapterTextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<int> get chapterNumber => $composableBuilder(
    column: $table.chapterNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get htmlContent => $composableBuilder(
    column: $table.htmlContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plainText =>
      $composableBuilder(column: $table.plainText, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<int> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$ChapterTextsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChapterTextsTable,
          ChapterTextRow,
          $$ChapterTextsTableFilterComposer,
          $$ChapterTextsTableOrderingComposer,
          $$ChapterTextsTableAnnotationComposer,
          $$ChapterTextsTableCreateCompanionBuilder,
          $$ChapterTextsTableUpdateCompanionBuilder,
          (
            ChapterTextRow,
            BaseReferences<_$AppDatabase, $ChapterTextsTable, ChapterTextRow>,
          ),
          ChapterTextRow,
          PrefetchHooks Function()
        > {
  $$ChapterTextsTableTableManager(_$AppDatabase db, $ChapterTextsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChapterTextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChapterTextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChapterTextsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bookId = const Value.absent(),
                Value<int> chapterNumber = const Value.absent(),
                Value<String> htmlContent = const Value.absent(),
                Value<String?> plainText = const Value.absent(),
                Value<String> sourceUrl = const Value.absent(),
                Value<int> parserVersion = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChapterTextsCompanion(
                bookId: bookId,
                chapterNumber: chapterNumber,
                htmlContent: htmlContent,
                plainText: plainText,
                sourceUrl: sourceUrl,
                parserVersion: parserVersion,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookId,
                required int chapterNumber,
                required String htmlContent,
                Value<String?> plainText = const Value.absent(),
                required String sourceUrl,
                required int parserVersion,
                required int cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChapterTextsCompanion.insert(
                bookId: bookId,
                chapterNumber: chapterNumber,
                htmlContent: htmlContent,
                plainText: plainText,
                sourceUrl: sourceUrl,
                parserVersion: parserVersion,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChapterTextsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChapterTextsTable,
      ChapterTextRow,
      $$ChapterTextsTableFilterComposer,
      $$ChapterTextsTableOrderingComposer,
      $$ChapterTextsTableAnnotationComposer,
      $$ChapterTextsTableCreateCompanionBuilder,
      $$ChapterTextsTableUpdateCompanionBuilder,
      (
        ChapterTextRow,
        BaseReferences<_$AppDatabase, $ChapterTextsTable, ChapterTextRow>,
      ),
      ChapterTextRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReadChaptersTableTableManager get readChapters =>
      $$ReadChaptersTableTableManager(_db, _db.readChapters);
  $$ReadingPlansTableTableManager get readingPlans =>
      $$ReadingPlansTableTableManager(_db, _db.readingPlans);
  $$PlanDaysTableTableManager get planDays =>
      $$PlanDaysTableTableManager(_db, _db.planDays);
  $$ChapterTextsTableTableManager get chapterTexts =>
      $$ChapterTextsTableTableManager(_db, _db.chapterTexts);
}
