// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_document_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetVaultDocumentModelCollection on Isar {
  IsarCollection<VaultDocumentModel> get vaultDocumentModels =>
      this.collection();
}

const VaultDocumentModelSchema = CollectionSchema(
  name: r'VaultDocumentModel',
  id: -6194866744757324144,
  properties: {
    r'activityRecords': PropertySchema(
      id: 0,
      name: r'activityRecords',
      type: IsarType.stringList,
    ),
    r'categoryId': PropertySchema(
      id: 1,
      name: r'categoryId',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deletedAt': PropertySchema(
      id: 3,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'encryptedMetadata': PropertySchema(
      id: 4,
      name: r'encryptedMetadata',
      type: IsarType.string,
    ),
    r'expiryDate': PropertySchema(
      id: 5,
      name: r'expiryDate',
      type: IsarType.dateTime,
    ),
    r'extractedText': PropertySchema(
      id: 6,
      name: r'extractedText',
      type: IsarType.string,
    ),
    r'filePath': PropertySchema(
      id: 7,
      name: r'filePath',
      type: IsarType.string,
    ),
    r'fileType': PropertySchema(
      id: 8,
      name: r'fileType',
      type: IsarType.byte,
      enumMap: _VaultDocumentModelfileTypeEnumValueMap,
    ),
    r'isFavorite': PropertySchema(
      id: 9,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'notes': PropertySchema(
      id: 10,
      name: r'notes',
      type: IsarType.string,
    ),
    r'reminderOffsets': PropertySchema(
      id: 11,
      name: r'reminderOffsets',
      type: IsarType.longList,
    ),
    r'remindersDisabled': PropertySchema(
      id: 12,
      name: r'remindersDisabled',
      type: IsarType.bool,
    ),
    r'tags': PropertySchema(
      id: 13,
      name: r'tags',
      type: IsarType.stringList,
    ),
    r'title': PropertySchema(
      id: 14,
      name: r'title',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 15,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'versionRecords': PropertySchema(
      id: 16,
      name: r'versionRecords',
      type: IsarType.stringList,
    )
  },
  estimateSize: _vaultDocumentModelEstimateSize,
  serialize: _vaultDocumentModelSerialize,
  deserialize: _vaultDocumentModelDeserialize,
  deserializeProp: _vaultDocumentModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'title': IndexSchema(
      id: -7636685945352118059,
      name: r'title',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'title',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'categoryId': IndexSchema(
      id: -8798048739239305339,
      name: r'categoryId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'categoryId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'notes': IndexSchema(
      id: 8092016287011465773,
      name: r'notes',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'notes',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'deletedAt': IndexSchema(
      id: -8969437169173379604,
      name: r'deletedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'deletedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _vaultDocumentModelGetId,
  getLinks: _vaultDocumentModelGetLinks,
  attach: _vaultDocumentModelAttach,
  version: '3.1.0+1',
);

int _vaultDocumentModelEstimateSize(
  VaultDocumentModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.activityRecords.length * 3;
  {
    for (var i = 0; i < object.activityRecords.length; i++) {
      final value = object.activityRecords[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.encryptedMetadata;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.extractedText;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.filePath.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.reminderOffsets.length * 8;
  bytesCount += 3 + object.tags.length * 3;
  {
    for (var i = 0; i < object.tags.length; i++) {
      final value = object.tags[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.versionRecords.length * 3;
  {
    for (var i = 0; i < object.versionRecords.length; i++) {
      final value = object.versionRecords[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _vaultDocumentModelSerialize(
  VaultDocumentModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.activityRecords);
  writer.writeLong(offsets[1], object.categoryId);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeDateTime(offsets[3], object.deletedAt);
  writer.writeString(offsets[4], object.encryptedMetadata);
  writer.writeDateTime(offsets[5], object.expiryDate);
  writer.writeString(offsets[6], object.extractedText);
  writer.writeString(offsets[7], object.filePath);
  writer.writeByte(offsets[8], object.fileType.index);
  writer.writeBool(offsets[9], object.isFavorite);
  writer.writeString(offsets[10], object.notes);
  writer.writeLongList(offsets[11], object.reminderOffsets);
  writer.writeBool(offsets[12], object.remindersDisabled);
  writer.writeStringList(offsets[13], object.tags);
  writer.writeString(offsets[14], object.title);
  writer.writeDateTime(offsets[15], object.updatedAt);
  writer.writeStringList(offsets[16], object.versionRecords);
}

VaultDocumentModel _vaultDocumentModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = VaultDocumentModel();
  object.activityRecords = reader.readStringList(offsets[0]) ?? [];
  object.categoryId = reader.readLongOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[3]);
  object.encryptedMetadata = reader.readStringOrNull(offsets[4]);
  object.expiryDate = reader.readDateTimeOrNull(offsets[5]);
  object.extractedText = reader.readStringOrNull(offsets[6]);
  object.filePath = reader.readString(offsets[7]);
  object.fileType = _VaultDocumentModelfileTypeValueEnumMap[
          reader.readByteOrNull(offsets[8])] ??
      VaultDocumentFileType.image;
  object.id = id;
  object.isFavorite = reader.readBool(offsets[9]);
  object.notes = reader.readStringOrNull(offsets[10]);
  object.reminderOffsets = reader.readLongList(offsets[11]) ?? [];
  object.remindersDisabled = reader.readBool(offsets[12]);
  object.tags = reader.readStringList(offsets[13]) ?? [];
  object.title = reader.readString(offsets[14]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[15]);
  object.versionRecords = reader.readStringList(offsets[16]) ?? [];
  return object;
}

P _vaultDocumentModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (_VaultDocumentModelfileTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          VaultDocumentFileType.image) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLongList(offset) ?? []) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readStringList(offset) ?? []) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 16:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _VaultDocumentModelfileTypeEnumValueMap = {
  'image': 0,
  'pdf': 1,
  'other': 2,
};
const _VaultDocumentModelfileTypeValueEnumMap = {
  0: VaultDocumentFileType.image,
  1: VaultDocumentFileType.pdf,
  2: VaultDocumentFileType.other,
};

Id _vaultDocumentModelGetId(VaultDocumentModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _vaultDocumentModelGetLinks(
    VaultDocumentModel object) {
  return [];
}

void _vaultDocumentModelAttach(
    IsarCollection<dynamic> col, Id id, VaultDocumentModel object) {
  object.id = id;
}

extension VaultDocumentModelQueryWhereSort
    on QueryBuilder<VaultDocumentModel, VaultDocumentModel, QWhere> {
  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhere>
      anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhere>
      anyCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'categoryId'),
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhere>
      anyDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'deletedAt'),
      );
    });
  }
}

extension VaultDocumentModelQueryWhere
    on QueryBuilder<VaultDocumentModel, VaultDocumentModel, QWhereClause> {
  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      titleEqualTo(String title) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'title',
        value: [title],
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      titleNotEqualTo(String title) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      createdAtNotEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [createdAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [],
        upper: [createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [lowerCreatedAt],
        includeLower: includeLower,
        upper: [upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      categoryIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'categoryId',
        value: [null],
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      categoryIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'categoryId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      categoryIdEqualTo(int? categoryId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'categoryId',
        value: [categoryId],
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      categoryIdNotEqualTo(int? categoryId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'categoryId',
              lower: [],
              upper: [categoryId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'categoryId',
              lower: [categoryId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'categoryId',
              lower: [categoryId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'categoryId',
              lower: [],
              upper: [categoryId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      categoryIdGreaterThan(
    int? categoryId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'categoryId',
        lower: [categoryId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      categoryIdLessThan(
    int? categoryId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'categoryId',
        lower: [],
        upper: [categoryId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      categoryIdBetween(
    int? lowerCategoryId,
    int? upperCategoryId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'categoryId',
        lower: [lowerCategoryId],
        includeLower: includeLower,
        upper: [upperCategoryId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'notes',
        value: [null],
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'notes',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      notesEqualTo(String? notes) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'notes',
        value: [notes],
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      notesNotEqualTo(String? notes) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'notes',
              lower: [],
              upper: [notes],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'notes',
              lower: [notes],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'notes',
              lower: [notes],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'notes',
              lower: [],
              upper: [notes],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'deletedAt',
        value: [null],
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'deletedAt',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      deletedAtEqualTo(DateTime? deletedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'deletedAt',
        value: [deletedAt],
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      deletedAtNotEqualTo(DateTime? deletedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deletedAt',
              lower: [],
              upper: [deletedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deletedAt',
              lower: [deletedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deletedAt',
              lower: [deletedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deletedAt',
              lower: [],
              upper: [deletedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      deletedAtGreaterThan(
    DateTime? deletedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'deletedAt',
        lower: [deletedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      deletedAtLessThan(
    DateTime? deletedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'deletedAt',
        lower: [],
        upper: [deletedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterWhereClause>
      deletedAtBetween(
    DateTime? lowerDeletedAt,
    DateTime? upperDeletedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'deletedAt',
        lower: [lowerDeletedAt],
        includeLower: includeLower,
        upper: [upperDeletedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension VaultDocumentModelQueryFilter
    on QueryBuilder<VaultDocumentModel, VaultDocumentModel, QFilterCondition> {
  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityRecords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activityRecords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activityRecords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activityRecords',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'activityRecords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'activityRecords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'activityRecords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'activityRecords',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityRecords',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'activityRecords',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activityRecords',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activityRecords',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activityRecords',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activityRecords',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activityRecords',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      activityRecordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activityRecords',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      categoryIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'categoryId',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      categoryIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'categoryId',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      categoryIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      categoryIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryId',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      categoryIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryId',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      categoryIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      deletedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      deletedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      deletedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deletedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      encryptedMetadataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'encryptedMetadata',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      encryptedMetadataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'encryptedMetadata',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      encryptedMetadataEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'encryptedMetadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      encryptedMetadataGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'encryptedMetadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      encryptedMetadataLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'encryptedMetadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      encryptedMetadataBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'encryptedMetadata',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      encryptedMetadataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'encryptedMetadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      encryptedMetadataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'encryptedMetadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      encryptedMetadataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'encryptedMetadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      encryptedMetadataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'encryptedMetadata',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      encryptedMetadataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'encryptedMetadata',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      encryptedMetadataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'encryptedMetadata',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      expiryDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'expiryDate',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      expiryDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'expiryDate',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      expiryDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expiryDate',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      expiryDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expiryDate',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      expiryDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expiryDate',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      expiryDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expiryDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      extractedTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'extractedText',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      extractedTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'extractedText',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      extractedTextEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'extractedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      extractedTextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'extractedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      extractedTextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'extractedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      extractedTextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'extractedText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      extractedTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'extractedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      extractedTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'extractedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      extractedTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'extractedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      extractedTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'extractedText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      extractedTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'extractedText',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      extractedTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'extractedText',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      filePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      filePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      filePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      filePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'filePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      filePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      filePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      filePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      filePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'filePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      filePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      filePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      fileTypeEqualTo(VaultDocumentFileType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileType',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      fileTypeGreaterThan(
    VaultDocumentFileType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileType',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      fileTypeLessThan(
    VaultDocumentFileType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileType',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      fileTypeBetween(
    VaultDocumentFileType lower,
    VaultDocumentFileType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      isFavoriteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFavorite',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      reminderOffsetsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reminderOffsets',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      reminderOffsetsElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reminderOffsets',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      reminderOffsetsElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reminderOffsets',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      reminderOffsetsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reminderOffsets',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      reminderOffsetsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reminderOffsets',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      reminderOffsetsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reminderOffsets',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      reminderOffsetsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reminderOffsets',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      reminderOffsetsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reminderOffsets',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      reminderOffsetsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reminderOffsets',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      reminderOffsetsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reminderOffsets',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      remindersDisabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remindersDisabled',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tags',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      tagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'versionRecords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'versionRecords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'versionRecords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'versionRecords',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'versionRecords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'versionRecords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'versionRecords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'versionRecords',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'versionRecords',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'versionRecords',
        value: '',
      ));
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'versionRecords',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'versionRecords',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'versionRecords',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'versionRecords',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'versionRecords',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterFilterCondition>
      versionRecordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'versionRecords',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension VaultDocumentModelQueryObject
    on QueryBuilder<VaultDocumentModel, VaultDocumentModel, QFilterCondition> {}

extension VaultDocumentModelQueryLinks
    on QueryBuilder<VaultDocumentModel, VaultDocumentModel, QFilterCondition> {}

extension VaultDocumentModelQuerySortBy
    on QueryBuilder<VaultDocumentModel, VaultDocumentModel, QSortBy> {
  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByEncryptedMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedMetadata', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByEncryptedMetadataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedMetadata', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByExpiryDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByExtractedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extractedText', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByExtractedTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extractedText', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByFileType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileType', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByFileTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileType', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByRemindersDisabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersDisabled', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByRemindersDisabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersDisabled', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension VaultDocumentModelQuerySortThenBy
    on QueryBuilder<VaultDocumentModel, VaultDocumentModel, QSortThenBy> {
  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByEncryptedMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedMetadata', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByEncryptedMetadataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedMetadata', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByExpiryDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByExtractedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extractedText', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByExtractedTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extractedText', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByFileType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileType', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByFileTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileType', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByRemindersDisabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersDisabled', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByRemindersDisabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersDisabled', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension VaultDocumentModelQueryWhereDistinct
    on QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct> {
  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByActivityRecords() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activityRecords');
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryId');
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByEncryptedMetadata({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'encryptedMetadata',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiryDate');
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByExtractedText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'extractedText',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByFilePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByFileType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileType');
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByNotes({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByReminderOffsets() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reminderOffsets');
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByRemindersDisabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remindersDisabled');
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags');
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentModel, QDistinct>
      distinctByVersionRecords() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'versionRecords');
    });
  }
}

extension VaultDocumentModelQueryProperty
    on QueryBuilder<VaultDocumentModel, VaultDocumentModel, QQueryProperty> {
  QueryBuilder<VaultDocumentModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<VaultDocumentModel, List<String>, QQueryOperations>
      activityRecordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activityRecords');
    });
  }

  QueryBuilder<VaultDocumentModel, int?, QQueryOperations>
      categoryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryId');
    });
  }

  QueryBuilder<VaultDocumentModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<VaultDocumentModel, DateTime?, QQueryOperations>
      deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<VaultDocumentModel, String?, QQueryOperations>
      encryptedMetadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'encryptedMetadata');
    });
  }

  QueryBuilder<VaultDocumentModel, DateTime?, QQueryOperations>
      expiryDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiryDate');
    });
  }

  QueryBuilder<VaultDocumentModel, String?, QQueryOperations>
      extractedTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'extractedText');
    });
  }

  QueryBuilder<VaultDocumentModel, String, QQueryOperations>
      filePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filePath');
    });
  }

  QueryBuilder<VaultDocumentModel, VaultDocumentFileType, QQueryOperations>
      fileTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileType');
    });
  }

  QueryBuilder<VaultDocumentModel, bool, QQueryOperations>
      isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<VaultDocumentModel, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<VaultDocumentModel, List<int>, QQueryOperations>
      reminderOffsetsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderOffsets');
    });
  }

  QueryBuilder<VaultDocumentModel, bool, QQueryOperations>
      remindersDisabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remindersDisabled');
    });
  }

  QueryBuilder<VaultDocumentModel, List<String>, QQueryOperations>
      tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }

  QueryBuilder<VaultDocumentModel, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<VaultDocumentModel, DateTime?, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<VaultDocumentModel, List<String>, QQueryOperations>
      versionRecordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'versionRecords');
    });
  }
}
