﻿namespace ServiceStack.OrmLite
{
    using System;
    using System.Data;
    using System.Linq.Expressions;
    using System.Text;

    public enum OnFkOption
    {
        Cascade,
        SetNull,
        NoAction,
        SetDefault,
        Restrict
    }

    public static class OrmLiteSchemaModifyApi
    {
        private static void InitUserFieldDefinition(Type modelType, FieldDefinition fieldDef)
        {
            if (fieldDef.PropertyInfo == null)
            {
                fieldDef.PropertyInfo = TypeProperties.Get(modelType).GetPublicProperty(fieldDef.Name);
            }
        }

        public static void AlterTable<T>(this IDbConnection dbConn, string command)
        {
            AlterTable(dbConn, typeof(T), command);
        }

        public static void AlterTable(this IDbConnection dbConn, Type modelType, string command)
        {
            var sql = $"ALTER TABLE {dbConn.GetDialectProvider().GetQuotedTableName(modelType.GetModelDefinition())} {command};";
            dbConn.ExecuteSql(sql);
        }

        public static void AddColumnWithCommand<T>(this IDbConnection dbConn, string command)
        {
            var modelDef = ModelDefinition<T>.Definition;

            var sql = $"ALTER TABLE {dbConn.GetDialectProvider().GetQuotedTableName(modelDef)} ADD {command};";
            dbConn.ExecuteSql(sql);
        }

        public static void AddColumn<T>(this IDbConnection dbConn, Expression<Func<T, object>> field)
        {
            var modelDef = ModelDefinition<T>.Definition;
            var fieldDef = modelDef.GetFieldDefinition(field);
            dbConn.AddColumn(typeof(T), fieldDef);
        }

        public static void AddColumn(this IDbConnection dbConn, Type modelType, FieldDefinition fieldDef)
        {
            InitUserFieldDefinition(modelType, fieldDef);

            var command = dbConn.GetDialectProvider().ToAddColumnStatement(modelType, fieldDef);
            dbConn.ExecuteSql(command);
        }

        public static void AlterColumn<T>(this IDbConnection dbConn, Expression<Func<T, object>> field)
        {
            var modelDef = ModelDefinition<T>.Definition;
            var fieldDef = modelDef.GetFieldDefinition<T>(field);
            dbConn.AlterColumn(typeof(T), fieldDef);
        }

        public static void AlterColumn(this IDbConnection dbConn, Type modelType, FieldDefinition fieldDef)
        {
            InitUserFieldDefinition(modelType, fieldDef);

            var command = dbConn.GetDialectProvider().ToAlterColumnStatement(modelType, fieldDef);
            dbConn.ExecuteSql(command);
        }

        public static void ChangeColumnName<T>(this IDbConnection dbConn,
            Expression<Func<T, object>> field,
            string oldColumnName)
        {
            var modelDef = ModelDefinition<T>.Definition;
            var fieldDef = modelDef.GetFieldDefinition<T>(field);
            dbConn.ChangeColumnName(typeof(T), fieldDef, oldColumnName);
        }

        public static void ChangeColumnName(this IDbConnection dbConn,
            Type modelType,
            FieldDefinition fieldDef,
            string oldColumnName)
        {
            var command = dbConn.GetDialectProvider().ToChangeColumnNameStatement(modelType, fieldDef, oldColumnName);
            dbConn.ExecuteSql(command);
        }

        public static void DropColumn<T>(this IDbConnection dbConn, Expression<Func<T, object>> field)
        {
            var modelDef = ModelDefinition<T>.Definition;
            var fieldDef = modelDef.GetFieldDefinition(field);
            dbConn.DropColumn(typeof(T), fieldDef.FieldName);
        }

        public static void DropColumn<T>(this IDbConnection dbConn, string columnName)
        {
            dbConn.DropColumn(typeof(T), columnName);
        }

        public static void DropColumn(this IDbConnection dbConn, Type modelType, string columnName)
        {
            dbConn.GetDialectProvider().DropColumn(dbConn, modelType, columnName);
        }

        public static void AddForeignKey<T, TForeign>(this IDbConnection dbConn,
            Expression<Func<T, object>> field,
            Expression<Func<TForeign, object>> foreignField,
            OnFkOption onUpdate,
            OnFkOption onDelete,
            string foreignKeyName = null)
        {
            var command = dbConn.GetDialectProvider().ToAddForeignKeyStatement(
                field, foreignField, onUpdate, onDelete, foreignKeyName);

            dbConn.ExecuteSql(command);
        }

        public static void DropPrimaryKey<T>(this IDbConnection dbConn, string name, bool online = true)
        {
            var provider = dbConn.GetDialectProvider();
            var modelDef = ModelDefinition<T>.Definition;

            var command = provider.GetDropPrimaryKeyConstraint(modelDef, name);

            dbConn.ExecuteSql(command);
        }

        public static void DropForeignKey<T>(this IDbConnection dbConn, string name)
        {
            var provider = dbConn.GetDialectProvider();
            var modelDef = ModelDefinition<T>.Definition;

            var command = provider.GetDropForeignKeyConstraint(modelDef, name);

            dbConn.ExecuteSql(command);
        }


        public static void CreateIndex<T>(this IDbConnection dbConn, Expression<Func<T, object>> field,
            string indexName = null, bool unique = false)
        {
            var command = dbConn.GetDialectProvider().ToCreateIndexStatement(field, indexName, unique);
            dbConn.ExecuteSql(command);
        }

        /// <summary>
        /// Drop Index of table
        /// </summary>
        /// <param name="dbConn">
        /// The db conn.
        /// </param>
        /// <typeparam name="T">
        /// </typeparam>
        public static void DropIndex<T>(this IDbConnection dbConn, string name = null)
        {
            var provider = dbConn.GetDialectProvider();
            var modelDef = ModelDefinition<T>.Definition;

            var command = provider.GetDropIndexConstraint(modelDef, name);

            dbConn.ExecuteSql(command);
        }

        public static void CreateViewIndex<T>(this IDbConnection dbConn, string name, string selectSql)
        {
            var provider = dbConn.GetDialectProvider();
            var modelDef = ModelDefinition<T>.Definition;

            var command = provider.GetCreateIndexView(modelDef, name, selectSql);

            dbConn.ExecuteSql(command);
        }

        public static void DropViewIndex<T>(this IDbConnection dbConn, string name)
        {
            var provider = dbConn.GetDialectProvider();
            var modelDef = ModelDefinition<T>.Definition;

            var command = provider.GetDropIndexView(modelDef, name);

            dbConn.ExecuteSql(command);
        }

        public static void CreateView<T>(this IDbConnection dbConn, StringBuilder selectSql)
        {
            var provider = dbConn.GetDialectProvider();
            var modelDef = ModelDefinition<T>.Definition;

            var command = provider.GetCreateView(modelDef, selectSql);

            dbConn.ExecuteSql(command);
        }

        public static void DropView<T>(this IDbConnection dbConn)
        {
            var provider = dbConn.GetDialectProvider();
            var modelDef = ModelDefinition<T>.Definition;

            var command = provider.GetDropView(modelDef);

            dbConn.ExecuteSql(command);
        }

        public static void DropFunction(this IDbConnection dbConn, string functionName)
        {
            var provider = dbConn.GetDialectProvider();

            var command = provider.GetDropFunction(functionName);

            dbConn.ExecuteSql(command);
        }
    }
}
