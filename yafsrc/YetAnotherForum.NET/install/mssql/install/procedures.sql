/*
  YAF SQL Stored Procedures File Created 03/01/06


  Remove Comments RegEx: \/\*(.*)\*\/
  Remove Extra Stuff: SET ANSI_NULLS ON\nGO\nSET QUOTED_IDENTIFIER ON\nGO\n\n\n

*/

/*****************************************************************************************************************************/
/***** BEGIN CREATE PROCEDURES ******/
/*****************************************************************************************************************************/

/* Procedures for "Thanks" Mod */

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}message_getallthanks]
    @MessageIDs varchar(max)
AS
BEGIN
-- vzrus says: the server version > 2000 ntext works too slowly with substring in the 2005
DECLARE @ParsedMessageIDs TABLE
      (
            MessageID int
      )

DECLARE @MessageID varchar(11), @Pos INT

SET @Pos = CHARINDEX(',', @MessageIDs, 1)
-- check here if the value is not empty
IF REPLACE(@MessageIDs, ',', '') <> ''
BEGIN
 WHILE @Pos > 0
                  BEGIN
                        SET @MessageID = LTRIM(RTRIM(LEFT(@MessageIDs, @Pos - 1)))
                        IF @MessageID <> ''
                        BEGIN
                              INSERT INTO @ParsedMessageIDs (MessageID) VALUES (CAST(@MessageID AS int)) --Use Appropriate conversion
                        END
                        SET @MessageIDs = RIGHT(@MessageIDs, LEN(@MessageIDs) - @Pos)
                        SET @Pos = CHARINDEX(',', @MessageIDs, 1)
                  END
                     -- to be sure that last value is inserted
                    IF (LEN(@MessageIDs) > 0)
                           INSERT INTO @ParsedMessageIDs (MessageID) VALUES (CAST(@MessageIDs AS int))
END
    SELECT a.MessageID, b.ThanksFromUserID AS FromUserID, b.ThanksDate,
    (SELECT COUNT(ThanksID) FROM [{databaseOwner}].[{objectQualifier}Thanks] b WHERE b.ThanksFromUserID=d.UserID) AS ThanksFromUserNumber,
    (SELECT COUNT(ThanksID) FROM [{databaseOwner}].[{objectQualifier}Thanks] b WHERE b.ThanksToUserID=d.UserID) AS ThanksToUserNumber,
    (SELECT COUNT(DISTINCT(MessageID)) FROM [{databaseOwner}].[{objectQualifier}Thanks] b WHERE b.ThanksToUserID=d.UserID) AS ThanksToUserPostsNumber
    FROM @ParsedMessageIDs a
    INNER JOIN [{databaseOwner}].[{objectQualifier}Message] d ON (d.MessageID=a.MessageID)
    LEFT JOIN [{databaseOwner}].[{objectQualifier}Thanks] b ON (b.MessageID = a.MessageID)
END
GO

/* End of procedures for "Thanks" Mod */

create procedure [{databaseOwner}].[{objectQualifier}active_list](@BoardID int,@Guests bit=0,@ShowCrawlers bit=0,@ActiveTime int,@StyledNicks bit=0,@UTCTIMESTAMP datetime) as
begin
    delete from [{databaseOwner}].[{objectQualifier}Active] where DATEDIFF(minute,LastActive,@UTCTIMESTAMP )>@ActiveTime
    -- we don't delete guest access
    delete from [{databaseOwner}].[{objectQualifier}ActiveAccess] where DATEDIFF(minute,LastActive,@UTCTIMESTAMP )>@ActiveTime AND  IsGuestX = 0
    -- select active
    if @Guests<>0
        select
            a.UserID,
            UserName = a.Name,
            UserDisplayName = a.DisplayName,
            c.IP,
            c.SessionID,
            c.ForumID,
            c.TopicID,
            ForumName = (select Name from [{databaseOwner}].[{objectQualifier}Forum] x where x.ForumID=c.ForumID),
            TopicName = (select Topic from [{databaseOwner}].[{objectQualifier}Topic] x where x.TopicID=c.TopicID),
            IsGuest = (select 1 from [{databaseOwner}].[{objectQualifier}UserGroup] x inner join [{databaseOwner}].[{objectQualifier}Group] y on y.GroupID=x.GroupID where x.UserID=a.UserID and (y.Flags & 2)<>0),
            IsCrawler = CONVERT(int, SIGN((c.Flags & 8))),
            IsHidden = ( a.IsActiveExcluded ),
            Style = case(@StyledNicks)
            when 1 then  a.UserStyle
            else ''	 end,
            a.Suspended,
            UserCount = 1,
            c.[Login],
            c.LastActive,
            c.Location,
            Active = DATEDIFF(minute,c.Login,c.LastActive),
            c.Browser,
            c.[Platform],
            c.ForumPage
        from
            [{databaseOwner}].[{objectQualifier}User] a
            JOIN [{databaseOwner}].[{objectQualifier}Rank] r on r.RankID=a.RankID
            INNER JOIN [{databaseOwner}].[{objectQualifier}Active] c ON c.UserID = a.UserID
        where
            c.BoardID = @BoardID

        order by
            c.LastActive desc
    else if @ShowCrawlers = 1 and @Guests = 0
        select
            a.UserID,
            UserName = a.Name,
            UserDisplayName = a.DisplayName,
            c.IP,
            c.SessionID,
            c.ForumID,
            c.TopicID,
            ForumName = (select Name from [{databaseOwner}].[{objectQualifier}Forum] x where x.ForumID=c.ForumID),
            TopicName = (select Topic from [{databaseOwner}].[{objectQualifier}Topic] x where x.TopicID=c.TopicID),
            IsGuest = (select 1 from [{databaseOwner}].[{objectQualifier}UserGroup] x inner join [{databaseOwner}].[{objectQualifier}Group] y on y.GroupID=x.GroupID where x.UserID=a.UserID and (y.Flags & 2)<>0),
            IsCrawler = CONVERT(int, SIGN((c.Flags & 8))),
            IsHidden = ( a.IsActiveExcluded ),
            Style = case(@StyledNicks)
            when 1 then  a.UserStyle
            else ''	 end,
            a.Suspended,
            UserCount = 1,
            c.[Login],
            c.LastActive,
            c.Location,
            Active = DATEDIFF(minute,c.Login,c.LastActive),
            c.Browser,
            c.[Platform],
            c.ForumPage
        from
            [{databaseOwner}].[{objectQualifier}User] a
            JOIN [{databaseOwner}].[{objectQualifier}Rank] r on r.RankID=a.RankID
            INNER JOIN [{databaseOwner}].[{objectQualifier}Active] c ON c.UserID = a.UserID
        where
            c.BoardID = @BoardID
               -- is registered or is crawler
               and ((c.Flags & 4) = 4 OR (c.Flags & 8) = 8)
        order by
            c.LastActive desc
    else
        select
            a.UserID,
            UserName = a.Name,
            UserDisplayName = a.DisplayName,
            c.IP,
            c.SessionID,
            c.ForumID,
            c.TopicID,
            ForumName = (select Name from [{databaseOwner}].[{objectQualifier}Forum] x where x.ForumID=c.ForumID),
            TopicName = (select Topic from [{databaseOwner}].[{objectQualifier}Topic] x where x.TopicID=c.TopicID),
            IsGuest = (select 1 from [{databaseOwner}].[{objectQualifier}UserGroup] x inner join [{databaseOwner}].[{objectQualifier}Group] y on y.GroupID=x.GroupID where x.UserID=a.UserID and (y.Flags & 2)<>0),
            IsCrawler = CONVERT(int, SIGN((c.Flags & 8))),
            IsHidden = ( a.IsActiveExcluded ),
            Style = case(@StyledNicks)
            when 1 then  a.UserStyle
            else ''	 end,
            a.Suspended,
            UserCount = 1,
            c.[Login],
            c.LastActive,
            c.Location,
            Active = DATEDIFF(minute,c.Login,c.LastActive),
            c.Browser,
            c.[Platform],
            c.ForumPage
        from
            [{databaseOwner}].[{objectQualifier}User] a
            JOIN [{databaseOwner}].[{objectQualifier}Rank] r on r.RankID=a.RankID
            INNER JOIN [{databaseOwner}].[{objectQualifier}Active] c ON c.UserID = a.UserID
        where
            c.BoardID = @BoardID and
            -- no guests
            not exists(
                select 1
                    from [{databaseOwner}].[{objectQualifier}UserGroup] x
                        inner join [{databaseOwner}].[{objectQualifier}Group] y ON y.GroupID=x.GroupID
                    where x.UserID=a.UserID and (y.Flags & 2)<>0
                )
        order by
            c.LastActive desc
end
GO

create procedure [{databaseOwner}].[{objectQualifier}active_list_user](@BoardID int, @UserID int, @Guests bit=0, @ShowCrawlers bit = 0, @ActiveTime int,@StyledNicks bit=0) as
begin
    -- select active
    if @Guests<>0
        select
            a.UserID,
            UserName = a.Name,
            UserDisplayName = a.DisplayName,
            c.IP,
            c.SessionID,
            c.ForumID,
            HasForumAccess = CONVERT(int,x.ReadAccess),
            c.TopicID,
            ForumName = (select [Name] from [{databaseOwner}].[{objectQualifier}Forum] x where x.ForumID=c.ForumID),
            TopicName = (select Topic from [{databaseOwner}].[{objectQualifier}Topic] x where x.TopicID=c.TopicID),
            IsGuest = ISNULL((select 1 from [{databaseOwner}].[{objectQualifier}UserGroup] x inner join [{databaseOwner}].[{objectQualifier}Group] y on y.GroupID=x.GroupID where x.UserID=a.UserID and (y.Flags & 2)<>0),0),
            IsCrawler = CONVERT(int, SIGN((c.Flags & 8))),
            IsHidden = ( a.IsActiveExcluded ),
            Style = case(@StyledNicks)
            when 1 then  a.UserStyle
            else ''	 end,
            a.Suspended,
            UserCount = 1,
            c.[Login],
            c.LastActive,
            c.Location,
            Active = DATEDIFF(minute,c.Login,c.LastActive),
            c.Browser,
            c.[Platform],
            c.ForumPage
        from
            [{databaseOwner}].[{objectQualifier}User] a
            JOIN [{databaseOwner}].[{objectQualifier}Rank] r on r.RankID=a.RankID
            inner join [{databaseOwner}].[{objectQualifier}Active] c
            ON c.UserID = a.UserID
            inner join [{databaseOwner}].[{objectQualifier}ActiveAccess] x
            ON (x.ForumID = ISNULL(c.ForumID,0))
        where
            c.BoardID = @BoardID AND x.UserID = @UserID
        order by
            c.LastActive desc
        else if @ShowCrawlers = 1 and @Guests = 0
            select
            a.UserID,
            UserName = a.Name,
            UserDisplayName = a.DisplayName,
            c.IP,
            c.SessionID,
            c.ForumID,
            HasForumAccess = CONVERT(int,x.ReadAccess),
            c.TopicID,
            ForumName = (select [Name] from [{databaseOwner}].[{objectQualifier}Forum] x where x.ForumID=c.ForumID),
            TopicName = (select Topic from [{databaseOwner}].[{objectQualifier}Topic] x where x.TopicID=c.TopicID),
            IsGuest = ISNULL((select 1 from [{databaseOwner}].[{objectQualifier}UserGroup] x inner join [{databaseOwner}].[{objectQualifier}Group] y on y.GroupID=x.GroupID where x.UserID=a.UserID and (y.Flags & 2)<>0),0),
            IsCrawler = CONVERT(int, SIGN((c.Flags & 8))),
            IsHidden = ( a.IsActiveExcluded ),
            Style = case(@StyledNicks)
            when 1 then  a.UserStyle
            else ''	 end,
            a.Suspended,
            UserCount = 1,
            c.[Login],
            c.LastActive,
            c.Location,
            Active = DATEDIFF(minute,c.Login,c.LastActive),
            c.Browser,
            c.[Platform],
            c.ForumPage
        from
            [{databaseOwner}].[{objectQualifier}User] a
            JOIN [{databaseOwner}].[{objectQualifier}Rank] r on r.RankID=a.RankID
            inner join [{databaseOwner}].[{objectQualifier}Active] c
            ON c.UserID = a.UserID
            inner join [{databaseOwner}].[{objectQualifier}ActiveAccess] x
            ON (x.ForumID = ISNULL(c.ForumID,0))
        where
            c.BoardID = @BoardID AND x.UserID = @UserID
            -- is registered or (is crawler and is registered
               and ((c.Flags & 4) = 4 OR (c.Flags & 8) = 8)
        order by
            c.LastActive desc
    else
        select
            a.UserID,
            UserName = a.Name,
            UserDisplayName = a.DisplayName,
            c.IP,
            c.SessionID,
            c.ForumID,
            HasForumAccess = CONVERT(int,x.ReadAccess),
            c.TopicID,
            ForumName = (select Name from [{databaseOwner}].[{objectQualifier}Forum] x where x.ForumID=c.ForumID),
            TopicName = (select Topic from [{databaseOwner}].[{objectQualifier}Topic] x where x.TopicID=c.TopicID),
            IsGuest = (select 1 from [{databaseOwner}].[{objectQualifier}UserGroup] x inner join [{databaseOwner}].[{objectQualifier}Group] y on y.GroupID=x.GroupID where x.UserID=a.UserID and (y.Flags & 2)<>0),
            IsCrawler = CONVERT(int, SIGN((c.Flags & 8))),
            IsHidden = ( a.IsActiveExcluded ),
            Style = case(@StyledNicks)
            when 1 then  a.UserStyle
            else ''	 end,
            a.Suspended,
            UserCount = 1,
            c.[Login],
            c.LastActive,
            c.Location,
            Active = DATEDIFF(minute,c.Login,c.LastActive),
            c.Browser,
            c.[Platform],
            c.ForumPage
        from
            [{databaseOwner}].[{objectQualifier}User] a
            JOIN [{databaseOwner}].[{objectQualifier}Rank] r on r.RankID=a.RankID
            INNER JOIN [{databaseOwner}].[{objectQualifier}Active] c
            ON c.UserID = a.UserID
            inner join [{databaseOwner}].[{objectQualifier}ActiveAccess] x
            ON (x.ForumID = ISNULL(c.ForumID,0))
            where
            c.BoardID = @BoardID  AND x.UserID = @UserID
         and
            not exists(
                select 1
                    from [{databaseOwner}].[{objectQualifier}UserGroup] x
                        inner join [{databaseOwner}].[{objectQualifier}Group] y ON y.GroupID=x.GroupID
                    where x.UserID=a.UserID and (y.Flags & 2)<>0
                )
        order by
            c.LastActive desc
end
GO

create procedure [{databaseOwner}].[{objectQualifier}active_listforum](@ForumID int, @StyledNicks bit = 0) as
begin
        select
        UserID		= a.UserID,
        UserName	= b.Name,
        UserDisplayName = b.DisplayName,
        IsHidden	= ( b.IsActiveExcluded ),
        IsCrawler	= Convert(int,a.Flags & 8),
        Style = case(@StyledNicks)
        when 1 then  b.UserStyle
        else ''	 end,
        b.Suspended,
        UserCount   = (SELECT COUNT(ac.UserID) from
        [{databaseOwner}].[{objectQualifier}Active] ac  where ac.UserID = a.UserID and ac.ForumID = @ForumID),
        Browser = a.Browser
    from
        [{databaseOwner}].[{objectQualifier}Active] a
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=a.UserID
    where
        a.ForumID = @ForumID
    group by
        a.UserID,
        b.DisplayName,
        b.Name,
        b.IsActiveExcluded,
        b.UserID,
        b.UserStyle,
        b.Suspended,
        a.Flags,
        a.Browser
    order by
        b.Name
end
GO

create procedure [{databaseOwner}].[{objectQualifier}active_listtopic](@TopicID int,@StyledNicks bit = 0) as
begin
        select
        UserID		= a.UserID,
        UserName	= b.Name,
        UserDisplayName = b.DisplayName,
        IsHidden = ( b.IsActiveExcluded ),
        IsCrawler	= Convert(int,a.Flags & 8),
        Style = case(@StyledNicks)
            when 1 then  b.UserStyle
            else ''	 end,
        b.Suspended,
        UserCount   = (SELECT COUNT(ac.UserID) from
        [{databaseOwner}].[{objectQualifier}Active] ac  where ac.UserID = a.UserID and ac.TopicID = @TopicID),
        Browser = a.Browser
    from
        [{databaseOwner}].[{objectQualifier}Active] a
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=a.UserID
    where
        a.TopicID = @TopicID
    group by
        a.UserID,
        b.DisplayName,
        b.Name,
        b.IsActiveExcluded,
        b.UserID,
        b.UserStyle,
        b.Suspended,
        a.Flags,
        a.Browser
    order by
        b.Name
end
GO

create procedure [{databaseOwner}].[{objectQualifier}active_stats](@BoardID int) as
begin
        select
        ActiveUsers = (select count(1) from [{databaseOwner}].[{objectQualifier}Active] x JOIN [{databaseOwner}].[{objectQualifier}User] usr ON x.UserID = usr.UserID where x.BoardID = @BoardID AND usr.IsActiveExcluded = 0),
        ActiveMembers = (select count(1) from [{databaseOwner}].[{objectQualifier}Active] x JOIN [{databaseOwner}].[{objectQualifier}User] usr ON x.UserID = usr.UserID where x.BoardID = @BoardID and exists(select 1 from [{databaseOwner}].[{objectQualifier}UserGroup] y inner join [{databaseOwner}].[{objectQualifier}Group] z on y.GroupID=z.GroupID where y.UserID=x.UserID and (z.Flags & 2)=0  AND usr.IsActiveExcluded = 0)),
        ActiveGuests = (select count(1) from [{databaseOwner}].[{objectQualifier}Active] x where x.BoardID = @BoardID and exists(select 1 from [{databaseOwner}].[{objectQualifier}UserGroup] y inner join [{databaseOwner}].[{objectQualifier}Group] z on y.GroupID=z.GroupID where y.UserID=x.UserID and (z.Flags & 2)<>0)),
        ActiveHidden = (select count(1) from [{databaseOwner}].[{objectQualifier}Active] x JOIN [{databaseOwner}].[{objectQualifier}User] usr ON x.UserID = usr.UserID where x.BoardID = @BoardID and exists(select 1 from [{databaseOwner}].[{objectQualifier}UserGroup] y inner join [{databaseOwner}].[{objectQualifier}Group] z on y.GroupID=z.GroupID where y.UserID=x.UserID and (z.Flags & 2)=0  AND usr.IsActiveExcluded = 1))
end
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}active_updatemaxstats]
(
    @BoardID int, @UTCTIMESTAMP datetime
)
AS
BEGIN
        DECLARE @count int, @max int, @maxStr nvarchar(255), @countStr nvarchar(255), @dtStr nvarchar(255)

    SET @count = ISNULL((SELECT COUNT(DISTINCT IP + '.' + CAST(UserID as varchar(10))) FROM [{databaseOwner}].[{objectQualifier}Active]  WHERE BoardID = @BoardID),0)
    SET @maxStr = (SELECT ISNULL([{databaseOwner}].[{objectQualifier}registry_value](N'maxusers', @BoardID), '1'))
    SET @max = CAST(@maxStr AS int)
    SET @countStr = CAST(@count AS nvarchar)
    SET @dtStr = CONVERT(nvarchar,@UTCTIMESTAMP,126)

    IF NOT EXISTS ( SELECT 1 FROM [{databaseOwner}].[{objectQualifier}Registry] WHERE BoardID = @BoardID and [Name] = N'maxusers')
    BEGIN
        INSERT INTO [{databaseOwner}].[{objectQualifier}Registry](BoardID,[Name],[Value]) VALUES (@BoardID,N'maxusers',CAST(@countStr AS nvarchar(max)))
        INSERT INTO [{databaseOwner}].[{objectQualifier}Registry](BoardID,[Name],[Value]) VALUES (@BoardID,N'maxuserswhen',CAST(@dtStr AS nvarchar(max)))
    END
    ELSE IF (@count > @max)
    BEGIN
        UPDATE [{databaseOwner}].[{objectQualifier}Registry] SET [Value] = CAST(@countStr AS nvarchar(max)) WHERE BoardID = @BoardID AND [Name] = N'maxusers'
        UPDATE [{databaseOwner}].[{objectQualifier}Registry] SET [Value] = CAST(@dtStr AS nvarchar(max)) WHERE BoardID = @BoardID AND [Name] = N'maxuserswhen'
    END
END
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}board_create](
    @BoardName 		nvarchar(50),
    @Culture varchar(10),
    @LanguageFile 	nvarchar(50),
    @UserName		nvarchar(255),
    @UserEmail		nvarchar(255),
    @UserKey		nvarchar(64),
    @IsHostAdmin	bit,
    @RolePrefix     nvarchar(255),
    @UTCTIMESTAMP datetime
) as
begin
    declare @BoardID				int
    declare @TimeZone				nvarchar(max)
    declare @ForumEmail				nvarchar(50)
    declare	@GroupIDAdmin			int
    declare	@GroupIDGuest			int
    declare @GroupIDMember			int
    declare	@AccessMaskIDAdmin		int
    declare @AccessMaskIDModerator	int
    declare @AccessMaskIDMember		int
    declare	@AccessMaskIDReadOnly	int
    declare @UserIDAdmin			int
    declare @UserIDGuest			int
    declare @RankIDAdmin			int
    declare @RankIDGuest			int
    declare @RankIDNewbie			int
    declare @RankIDMember			int
    declare @RankIDAdvanced			int
    declare	@CategoryID				int
    declare	@ForumID				int
    declare @UserFlags				int

    -- Board
    INSERT INTO [{databaseOwner}].[{objectQualifier}Board](Name) values(@BoardName)
    SET @BoardID = SCOPE_IDENTITY()

    SET @TimeZone = (SELECT ISNULL([{databaseOwner}].[{objectQualifier}registry_value](N'TimeZone', @BoardID), N'Dateline Standard Time'))
    SET @ForumEmail = (SELECT [{databaseOwner}].[{objectQualifier}registry_value](N'ForumEmail', @BoardID))

    EXEC [{databaseOwner}].[{objectQualifier}registry_save] 'culture',@Culture,@BoardID
    EXEC [{databaseOwner}].[{objectQualifier}registry_save] 'language',@LanguageFile,@BoardID

    -- Rank
    INSERT INTO [{databaseOwner}].[{objectQualifier}Rank](BoardID,Name,Flags,MinPosts,PMLimit,Style,SortOrder) VALUES (@BoardID,'Administration',0,null,2147483647,'default!font-size: 8pt; color: #811334/yafpro!font-size: 8pt; color:blue',0)
    SET @RankIDAdmin = SCOPE_IDENTITY()
    INSERT INTO [{databaseOwner}].[{objectQualifier}Rank](BoardID,Name,Flags,MinPosts,PMLimit,SortOrder) VALUES(@BoardID,'Guest',0,null,0,100)
    SET @RankIDGuest = SCOPE_IDENTITY()
    INSERT INTO [{databaseOwner}].[{objectQualifier}Rank](BoardID,Name,Flags,MinPosts,PMLimit,SortOrder) VALUES(@BoardID,'Newbie',3,0,10,3)
    SET @RankIDNewbie = SCOPE_IDENTITY()
    INSERT INTO [{databaseOwner}].[{objectQualifier}Rank](BoardID,Name,Flags,MinPosts,PMLimit,SortOrder) VALUES(@BoardID,'Member',2,10,30,2)
    SET @RankIDMember = SCOPE_IDENTITY()
    INSERT INTO [{databaseOwner}].[{objectQualifier}Rank](BoardID,Name,Flags,MinPosts,PMLimit,SortOrder) VALUES(@BoardID,'Advanced Member',2,30,100,1)
    SET @RankIDAdvanced = SCOPE_IDENTITY()

    -- AccessMask
    INSERT INTO [{databaseOwner}].[{objectQualifier}AccessMask](BoardID,Name,Flags,SortOrder)
    VALUES(@BoardID,'Admin Access',1023 + 1024,4)
    SET @AccessMaskIDAdmin = SCOPE_IDENTITY()
    INSERT INTO [{databaseOwner}].[{objectQualifier}AccessMask](BoardID,Name,Flags,SortOrder)
    VALUES(@BoardID,'Moderator Access',487 + 1024,3)
    SET @AccessMaskIDModerator = SCOPE_IDENTITY()
    INSERT INTO [{databaseOwner}].[{objectQualifier}AccessMask](BoardID,Name,Flags,SortOrder)
    VALUES(@BoardID,'Member Access',423 + 1024,2)
    SET @AccessMaskIDMember = SCOPE_IDENTITY()
    INSERT INTO [{databaseOwner}].[{objectQualifier}AccessMask](BoardID,Name,Flags,SortOrder)
    VALUES(@BoardID,'Read Only Access',1,1)
    SET @AccessMaskIDReadOnly = SCOPE_IDENTITY()
    INSERT INTO [{databaseOwner}].[{objectQualifier}AccessMask](BoardID,Name,Flags,SortOrder)
    VALUES(@BoardID,'No Access',0,0)

    -- Group
    INSERT INTO [{databaseOwner}].[{objectQualifier}Group](BoardID,Name,Flags,PMLimit,Style,SortOrder,UsrSigChars,UsrSigBBCodes,UsrAlbums,UsrAlbumImages) values(@BoardID, ISNULL(@RolePrefix,'') + 'Administrators',1,2147483647,'default!font-size: 8pt; color: red/yafpro!font-size: 8pt; color:blue',0,256,'URL,IMG,SPOILER,QUOTE',10,120)
    set @GroupIDAdmin = SCOPE_IDENTITY()
    INSERT INTO [{databaseOwner}].[{objectQualifier}Group](BoardID,Name,Flags,PMLimit,Style,SortOrder,UsrSigChars,UsrSigBBCodes,UsrAlbums,UsrAlbumImages) values(@BoardID,'Guests',2,0,'default!font-size: 8pt; font-style: italic; font-weight: bold; color: #0c7333/yafpro!font-size: 8pt; color: #6e1987',1,0,null,0,0)
    SET @GroupIDGuest = SCOPE_IDENTITY()
    INSERT INTO [{databaseOwner}].[{objectQualifier}Group](BoardID,Name,Flags,PMLimit,SortOrder,UsrSigChars,UsrSigBBCodes,UsrAlbums,UsrAlbumImages) values(@BoardID,ISNULL(@RolePrefix,'') + 'Registered',4,100,1,128,'URL,IMG,SPOILER,QUOTE',5,30)
    SET @GroupIDMember = SCOPE_IDENTITY()

    -- User (GUEST)
    INSERT INTO [{databaseOwner}].[{objectQualifier}User](BoardID,RankID,[Name],DisplayName,[Password],Joined,LastVisit,NumPosts,TimeZone,Email,Flags)
    VALUES(@BoardID,@RankIDGuest,'Guest','Guest','na',@UTCTIMESTAMP ,@UTCTIMESTAMP ,0,@TimeZone,@ForumEmail,6)
    SET @UserIDGuest = SCOPE_IDENTITY()

    SET @UserFlags = 2
    if @IsHostAdmin<>0 SET @UserFlags = 3

    -- User (ADMIN)
    INSERT INTO [{databaseOwner}].[{objectQualifier}User](BoardID,RankID,[Name],DisplayName, [Password], Email,ProviderUserKey, Joined,LastVisit,NumPosts,TimeZone,Flags)
    VALUES(@BoardID,@RankIDAdmin,@UserName,@UserName,'na',@UserEmail,@UserKey,@UTCTIMESTAMP ,@UTCTIMESTAMP ,0,@TimeZone,@UserFlags)
    SET @UserIDAdmin = SCOPE_IDENTITY()

    -- UserGroup
    INSERT INTO [{databaseOwner}].[{objectQualifier}UserGroup](UserID,GroupID) VALUES(@UserIDAdmin,@GroupIDAdmin)
    INSERT INTO [{databaseOwner}].[{objectQualifier}UserGroup](UserID,GroupID) VALUES(@UserIDGuest,@GroupIDGuest)

    -- Category
    INSERT INTO [{databaseOwner}].[{objectQualifier}Category](BoardID,Name,SortOrder) VALUES(@BoardID,'Test Category',1)
    set @CategoryID = SCOPE_IDENTITY()

    -- Forum
    INSERT INTO [{databaseOwner}].[{objectQualifier}Forum](CategoryID,Name,Description,SortOrder,NumTopics,NumPosts,Flags)
    VALUES(@CategoryID,'Test Forum','A test forum',1,0,0,4)
    set @ForumID = SCOPE_IDENTITY()

    -- ForumAccess
    INSERT INTO [{databaseOwner}].[{objectQualifier}ForumAccess](GroupID,ForumID,AccessMaskID) VALUES(@GroupIDAdmin,@ForumID,@AccessMaskIDAdmin)
    INSERT INTO [{databaseOwner}].[{objectQualifier}ForumAccess](GroupID,ForumID,AccessMaskID) VALUES(@GroupIDGuest,@ForumID,@AccessMaskIDReadOnly)
    INSERT INTO [{databaseOwner}].[{objectQualifier}ForumAccess](GroupID,ForumID,AccessMaskID) VALUES(@GroupIDMember,@ForumID,@AccessMaskIDMember)

    SELECT @BoardID;
end
GO

create procedure [{databaseOwner}].[{objectQualifier}board_delete](@BoardID int) as
begin
    --- Delete all forums of the board
    declare @tmpForumID int;
    declare forum_cursor cursor for
        select ForumID
        from [{databaseOwner}].[{objectQualifier}Forum] a join [{databaseOwner}].[{objectQualifier}Category] b on a.CategoryID=b.CategoryID
        where b.BoardID=@BoardID
        order by ForumID desc

    open forum_cursor
    fetch next from forum_cursor into @tmpForumID
    while @@FETCH_STATUS = 0
    begin
        exec [{databaseOwner}].[{objectQualifier}forum_delete] @tmpForumID;
        fetch next from forum_cursor into @tmpForumID
    end
    close forum_cursor
    deallocate forum_cursor

	--- Delete user
	declare @tmpUserID int;
    declare user_cursor cursor for
        select UserID
        from [{databaseOwner}].[{objectQualifier}User] 
		where  BoardID=@BoardID

    open user_cursor
    fetch next from user_cursor into @tmpUserID
    while @@FETCH_STATUS = 0
    begin
        exec [{databaseOwner}].[{objectQualifier}user_delete] @tmpUserID;
        fetch next from user_cursor into @tmpUserID
    end
    close user_cursor
    deallocate user_cursor

	--- Delete Group
	declare @tmpGroupID int;
    declare group_cursor cursor for
        select GroupID
        from [{databaseOwner}].[{objectQualifier}Group] 
		where  BoardID=@BoardID

    open group_cursor
    fetch next from group_cursor into @tmpGroupID
    while @@FETCH_STATUS = 0
    begin
        exec [{databaseOwner}].[{objectQualifier}group_delete] @tmpGroupID;
        fetch next from group_cursor into @tmpGroupID
    end
    close group_cursor
    deallocate group_cursor

    delete from [{databaseOwner}].[{objectQualifier}ForumAccess] where exists(select 1 from [{databaseOwner}].[{objectQualifier}Group] x where x.GroupID=[{databaseOwner}].[{objectQualifier}ForumAccess].GroupID and x.BoardID=@BoardID)
    delete from [{databaseOwner}].[{objectQualifier}Forum] where exists(select 1 from [{databaseOwner}].[{objectQualifier}Category] x where x.CategoryID=[{databaseOwner}].[{objectQualifier}Forum].CategoryID and x.BoardID=@BoardID)
    delete from [{databaseOwner}].[{objectQualifier}Category] where BoardID=@BoardID
    delete from [{databaseOwner}].[{objectQualifier}ActiveAccess] where BoardID=@BoardID
    delete from [{databaseOwner}].[{objectQualifier}Active] where BoardID=@BoardID
    delete from [{databaseOwner}].[{objectQualifier}Rank] where BoardID=@BoardID
    delete from [{databaseOwner}].[{objectQualifier}AccessMask] where BoardID=@BoardID
    delete from [{databaseOwner}].[{objectQualifier}BBCode] where BoardID=@BoardID
    delete from [{databaseOwner}].[{objectQualifier}Medal] where BoardID=@BoardID
    delete from [{databaseOwner}].[{objectQualifier}Replace_Words] where BoardId=@BoardID
	delete from [{databaseOwner}].[{objectQualifier}Spam_Words] where BoardId=@BoardID
    delete from [{databaseOwner}].[{objectQualifier}NntpServer] where BoardID=@BoardID
    delete from [{databaseOwner}].[{objectQualifier}BannedIP] where BoardID=@BoardID
    delete from [{databaseOwner}].[{objectQualifier}Registry] where BoardID=@BoardID
    delete from [{databaseOwner}].[{objectQualifier}Board] where BoardID=@BoardID
end
GO

create procedure [{databaseOwner}].[{objectQualifier}board_poststats](@BoardID int, @StyledNicks bit = 0, @ShowNoCountPosts bit = 0, @GetDefaults bit = 0 ) as
BEGIN

-- vzrus: while  a new installation or like this we don't have the row and should return a dummy data
IF @GetDefaults <= 0
BEGIN
        SELECT TOP 1
        Posts = (select count(1) from [{databaseOwner}].[{objectQualifier}Message] a join [{databaseOwner}].[{objectQualifier}Topic] b on b.TopicID=a.TopicID join [{databaseOwner}].[{objectQualifier}Forum] c on c.ForumID=b.ForumID join [{databaseOwner}].[{objectQualifier}Category] d on d.CategoryID=c.CategoryID where d.BoardID=@BoardID AND (a.Flags & 24)=16),
        Topics = (select count(1) from [{databaseOwner}].[{objectQualifier}Topic] a join [{databaseOwner}].[{objectQualifier}Forum] b on b.ForumID=a.ForumID join [{databaseOwner}].[{objectQualifier}Category] c on c.CategoryID=b.CategoryID where c.BoardID=@BoardID AND a.IsDeleted = 0),
        Forums = (select count(1) from [{databaseOwner}].[{objectQualifier}Forum] a join [{databaseOwner}].[{objectQualifier}Category] b on b.CategoryID=a.CategoryID where b.BoardID=@BoardID),
        LastPostInfoID	= 1,
        LastPost	= a.Posted,
        LastUserID	= a.UserID,
        LastUser	= e.Name,
        LastUserDisplayName	= e.DisplayName,
        LastUserStyle =  e.UserStyle,
        LastUserSuspended = e.Suspended
            FROM
                [{databaseOwner}].[{objectQualifier}Message] a
				join [{databaseOwner}].[{objectQualifier}Topic] b on b.TopicID=a.TopicID
                join [{databaseOwner}].[{objectQualifier}Forum] c on c.ForumID=b.ForumID
                join [{databaseOwner}].[{objectQualifier}Category] d on d.CategoryID=c.CategoryID
                join [{databaseOwner}].[{objectQualifier}User] e on e.UserID=a.UserID
            WHERE
                (a.Flags & 24) = 16
                AND b.IsDeleted = 0
                AND d.BoardID = @BoardID
                AND c.[IsNoCount] <> (CASE WHEN @ShowNoCountPosts > 0 THEN -1 ELSE 1 END)
            ORDER BY
                a.Posted DESC
        END
        ELSE
        BEGIN
        SELECT
        Posts = 0,
        Topics = 0,
        Forums = 1,
        LastPostInfoID	= 1,
        LastPost	= null,
        LastUserID	= null,
        LastUser	= null,
        LastUserDisplayName	= null,
        LastUserStyle = '',
        LastUserSuspended = null
        END
        -- this can be in any very rare updatable cached place
        DECLARE @linkDate datetime = GETUTCDATE()
        DELETE FROM [{databaseOwner}].[{objectQualifier}TopicReadTracking] where TopicID IN (SELECT TopicID FROM [{databaseOwner}].[{objectQualifier}Topic] where TopicMovedID IS NOT NULL AND LinkDate IS NOT NULL AND LinkDate < @linkDate)
        DELETE FROM [{databaseOwner}].[{objectQualifier}Topic] where TopicMovedID IS NOT NULL AND LinkDate IS NOT NULL AND LinkDate < @linkDate

END
GO

create procedure [{databaseOwner}].[{objectQualifier}board_userstats](@BoardID int) as
BEGIN
        SELECT
        Members = (select count(1) from [{databaseOwner}].[{objectQualifier}User] a where a.BoardID=@BoardID AND (Flags & 2) = 2 AND (a.Flags & 4) = 0),
        MaxUsers = (SELECT top 1 [{databaseOwner}].[{objectQualifier}registry_value](N'maxusers', @BoardID)),
        MaxUsersWhen = (SELECT top 1 [{databaseOwner}].[{objectQualifier}registry_value](N'maxuserswhen', @BoardID)),
        LastMemberInfo.*
    FROM
        (
            SELECT TOP 1
                LastMemberInfoID= 1,
                LastMemberID	= UserID,
                LastMember	= [Name],
                LastMemberDisplayName	= [DisplayName],
                LastMemberStyle = UserStyle,
                LastMemberSuspended = Suspended
            FROM
                [{databaseOwner}].[{objectQualifier}User]
            WHERE
               -- is approved
                (Flags & 2) = 2
                -- is not a guest
                AND (Flags & 4) <> 4
                AND BoardID = @BoardID
            ORDER BY
                Joined DESC
        ) as LastMemberInfo

END
GO

create procedure [{databaseOwner}].[{objectQualifier}board_stats]
    @BoardID	int = null
as
begin
        if (@BoardID is null) begin
        select
            NumPosts	= (select count(1) from [{databaseOwner}].[{objectQualifier}Message] where IsApproved = 1 AND IsDeleted = 0),
            NumTopics	= (select count(1) from [{databaseOwner}].[{objectQualifier}Topic] where IsDeleted = 0),
            NumUsers	= (select count(1) from [{databaseOwner}].[{objectQualifier}User] where IsApproved = 1),
            BoardStart	= (select min(Joined) from [{databaseOwner}].[{objectQualifier}User])
    end
    else begin
        select
            NumPosts	= (select count(1)
                                from [{databaseOwner}].[{objectQualifier}Message] a
                                join [{databaseOwner}].[{objectQualifier}Topic] b ON a.TopicID=b.TopicID
                                join [{databaseOwner}].[{objectQualifier}Forum] c ON b.ForumID=c.ForumID
                                join [{databaseOwner}].[{objectQualifier}Category] d ON c.CategoryID=d.CategoryID
                                where a.IsApproved = 1 AND a.IsDeleted = 0 and b.IsDeleted = 0 AND d.BoardID=@BoardID
                            ),
            NumTopics	= (select count(1)
                                from [{databaseOwner}].[{objectQualifier}Topic] a
                                join [{databaseOwner}].[{objectQualifier}Forum] b ON a.ForumID=b.ForumID
                                join [{databaseOwner}].[{objectQualifier}Category] c ON b.CategoryID=c.CategoryID
                                where c.BoardID=@BoardID AND a.IsDeleted = 0
                            ),
            NumUsers	= (select count(1) from [{databaseOwner}].[{objectQualifier}User] where IsApproved = 1 and BoardID=@BoardID),
            BoardStart	= (select min(Joined) from [{databaseOwner}].[{objectQualifier}User] where BoardID=@BoardID)
    end
end
GO

create procedure [{databaseOwner}].[{objectQualifier}category_list](@BoardID int,@CategoryID int=null) as
begin
        if @CategoryID is null
        select * from [{databaseOwner}].[{objectQualifier}Category] where BoardID = @BoardID order by SortOrder
    else
        select * from [{databaseOwner}].[{objectQualifier}Category] where BoardID = @BoardID and CategoryID = @CategoryID
end
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}checkemail_update](@Hash nvarchar(32)) as
begin
        declare @UserID int
    declare @CheckEmailID int
    declare @Email nvarchar(255)

    set @UserID = null

    select
        @CheckEmailID = CheckEmailID,
        @UserID = UserID,
        @Email = Email
    from
        [{databaseOwner}].[{objectQualifier}CheckEmail]
    where
        Hash = @Hash

    if @UserID is null
    begin
        select convert(nvarchar(64),NULL) as ProviderUserKey, convert(nvarchar(255),NULL) as Email
        return
    end

    -- Update new user email
    update [{databaseOwner}].[{objectQualifier}User] set Email = LOWER(@Email), Flags = Flags | 2 where UserID = @UserID
    delete [{databaseOwner}].[{objectQualifier}CheckEmail] where CheckEmailID = @CheckEmailID

    -- return the UserProviderKey
    SELECT ProviderUserKey, Email, UserID FROM [{databaseOwner}].[{objectQualifier}User] WHERE UserID = @UserID
end
GO

create procedure [{databaseOwner}].[{objectQualifier}eventlog_list](@BoardID int, @PageUserID int, @MaxRows int, @MaxDays int,  @PageIndex int,
   @PageSize int, @SinceDate datetime, @ToDate datetime, @EventIDs varchar(8000) = null,
@UTCTIMESTAMP datetime) as
begin
   declare @TotalRows int
   declare @FirstSelectRowNumber int
   declare @FirstSelectRowID int
   DECLARE @ParsedEventIDs TABLE
      (
            EventID int
      )

DECLARE @EventID varchar(11), @Pos INT
SET @Pos = CHARINDEX(',', @EventIDs, 1)
-- check here if the value is not empty
IF REPLACE(@EventIDs, ',', '') <> ''
BEGIN
 WHILE @Pos > 0
                  BEGIN
                        SET @EventID = LTRIM(RTRIM(LEFT(@EventIDs, @Pos - 1)))
                        IF @EventID <> ''
                        BEGIN
                              INSERT INTO @ParsedEventIDs (EventID) VALUES (CAST(@EventID AS int)) --Use Appropriate conversion
                        END
                        SET @EventIDs = RIGHT(@EventIDs, LEN(@EventIDs) - @Pos)
                        SET @Pos = CHARINDEX(',', @EventIDs, 1)
                  END
                     -- to be sure that last value is inserted
                    IF (LEN(@EventIDs) > 0)
                           INSERT INTO @ParsedEventIDs (EventID) VALUES (CAST(@EventIDs AS int))
END

-- delete entries older than 10 days
    delete from [{databaseOwner}].[{objectQualifier}EventLog] where EventTime+@MaxDays<@UTCTIMESTAMP

    -- or if there are more then 1000
    if ((select count(1) from [{databaseOwner}].[{objectQualifier}eventlog]) >= @MaxRows + 50)
    begin
        delete from [{databaseOwner}].[{objectQualifier}EventLog] WHERE EventLogID IN (SELECT TOP 100 EventLogID FROM [{databaseOwner}].[{objectQualifier}EventLog] ORDER BY EventTime)
    end

    set nocount on
     set @PageIndex = @PageIndex + 1
    if (exists (select top 1 1 from [{databaseOwner}].[{objectQualifier}User] where ((Flags & 1) = 1 and UserID = @PageUserID)))
    begin
      set @FirstSelectRowNumber = 0
      set @FirstSelectRowID = 0
      set @TotalRows = 0

        select @TotalRows = count(1) from
        [{databaseOwner}].[{objectQualifier}EventLog] a
        left join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=a.UserID
        where
        (b.UserID IS NULL or b.BoardID = @BoardID)	and ((@EventIDs IS NULL )  OR  a.[Type] IN (select * from @ParsedEventIDs))  and EventTime between @SinceDate and @ToDate

        select @FirstSelectRowNumber = (@PageIndex - 1) * @PageSize + 1

    if (@FirstSelectRowNumber <= @TotalRows)
        begin
           -- find first selectedrowid

    set rowcount @FirstSelectRowNumber
   end
   else
   begin
   set rowcount 1
   end

        select @FirstSelectRowID = EventLogID
       from
        [{databaseOwner}].[{objectQualifier}EventLog] a
        left join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=a.UserID
        where
        (b.UserID IS NULL or b.BoardID = @BoardID) and (@EventIDs IS NULL OR  a.[Type] IN (select * from @ParsedEventIDs))  and a.EventTime between @SinceDate and @ToDate
        order by a.EventLogID desc

      set rowcount @PageSize
      select
        a.*,
        ISNULL(b.[Name],'System') as [Name],
        TotalRows = @TotalRows
    from
        [{databaseOwner}].[{objectQualifier}EventLog] a
        left join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=a.UserID
      where EventLogID <= @FirstSelectRowID  and (b.UserID IS NULL or b.BoardID = @BoardID)	and (@EventIDs IS NULL OR  a.[Type] IN (select * from @ParsedEventIDs)) -- and a.EventTime between @SinceDate and @ToDate
      order by a.EventLogID   desc
   end
else
begin
        select @TotalRows = count(1)  from
        [{databaseOwner}].[{objectQualifier}EventLog] a
        left join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=a.UserID
    where
        (b.UserID IS NULL or b.BoardID = @BoardID)		and (@EventIDs IS NULL OR  a.[Type] IN (select * from @ParsedEventIDs))	 and a.EventTime between @SinceDate and @ToDate

        select @FirstSelectRowNumber = (@PageIndex - 1) * @PageSize + 1
                   -- find first selectedrowid
   if (@TotalRows > 0)
   begin
    set rowcount @FirstSelectRowNumber
   end
   else
   begin
   set rowcount 1
   end

        select @FirstSelectRowID = EventLogID
      from
        [{databaseOwner}].[{objectQualifier}EventLog] a
        left join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=a.UserID
    where
        (b.UserID IS NULL or b.BoardID = @BoardID)	and (@EventIDs IS NULL OR  a.[Type] IN (select * from @ParsedEventIDs))	 and a.EventTime between @SinceDate and @ToDate
        order by  a.EventLogID   desc

      set rowcount @PageSize
      select
      a.*,
        ISNULL(b.[Name],'System') as [Name],
        TotalRows = @TotalRows
         from
        [{databaseOwner}].[{objectQualifier}EventLog] a
        left join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=a.UserID
    where	  EventLogID <= @FirstSelectRowID and (b.UserID IS NULL or b.BoardID = @BoardID) and (@EventIDs IS NULL OR  a.[Type] IN (select * from @ParsedEventIDs)) and a.EventTime between @SinceDate and @ToDate
      order by a.EventLogID  desc
   end
   set rowcount 0
 set nocount off

end
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}forum_delete](@ForumID int) as
begin
        -- Maybe an idea to use cascading foreign keys instead? Too bad they don't work on MS SQL 7.0...
    update [{databaseOwner}].[{objectQualifier}Forum] set LastMessageID=null,LastTopicID=null where ForumID=@ForumID
    update [{databaseOwner}].[{objectQualifier}Topic] set LastMessageID=null where ForumID=@ForumID
    update [{databaseOwner}].[{objectQualifier}Active] set ForumID=null where ForumID=@ForumID
    delete from [{databaseOwner}].[{objectQualifier}WatchTopic] from [{databaseOwner}].[{objectQualifier}Topic] where [{databaseOwner}].[{objectQualifier}Topic].ForumID = @ForumID and [{databaseOwner}].[{objectQualifier}WatchTopic].TopicID = [{databaseOwner}].[{objectQualifier}Topic].TopicID
    delete from [{databaseOwner}].[{objectQualifier}Active] from [{databaseOwner}].[{objectQualifier}Topic] where [{databaseOwner}].[{objectQualifier}Topic].ForumID = @ForumID and [{databaseOwner}].[{objectQualifier}Active].TopicID = [{databaseOwner}].[{objectQualifier}Topic].TopicID
    delete from [{databaseOwner}].[{objectQualifier}NntpTopic] from [{databaseOwner}].[{objectQualifier}NntpForum] where [{databaseOwner}].[{objectQualifier}NntpForum].ForumID = @ForumID and [{databaseOwner}].[{objectQualifier}NntpTopic].NntpForumID = [{databaseOwner}].[{objectQualifier}NntpForum].NntpForumID
    delete from [{databaseOwner}].[{objectQualifier}NntpForum] where ForumID=@ForumID
    delete from [{databaseOwner}].[{objectQualifier}WatchForum] where ForumID = @ForumID
    delete from [{databaseOwner}].[{objectQualifier}ForumReadTracking] where ForumID = @ForumID

    -- BAI CHANGED 02.02.2004
    -- Delete topics, messages and attachments

    declare @tmpTopicID int;
    declare topic_cursor cursor for
        select TopicID from [{databaseOwner}].[{objectQualifier}Topic]
        where ForumID = @ForumID
        order by TopicID desc

    open topic_cursor

    fetch next from topic_cursor
    into @tmpTopicID

    -- Check @@FETCH_STATUS to see if there are any more rows to fetch.
    while @@FETCH_STATUS = 0
    begin
        exec [{databaseOwner}].[{objectQualifier}topic_delete] @tmpTopicID,1,1;

       -- This is executed as long as the previous fetch succeeds.
        fetch next from topic_cursor
        into @tmpTopicID
    end

    close topic_cursor
    deallocate topic_cursor

    -- TopicDelete finished
    -- END BAI CHANGED 02.02.2004

    delete from [{databaseOwner}].[{objectQualifier}ForumAccess] where ForumID = @ForumID
    --ABOT CHANGED
    --Delete UserForums Too
    delete from [{databaseOwner}].[{objectQualifier}UserForum] where ForumID = @ForumID
    --END ABOT CHANGED 09.04.2004
    delete from [{databaseOwner}].[{objectQualifier}Forum] where ForumID = @ForumID
end

GO

create procedure [{databaseOwner}].[{objectQualifier}forum_listread](@BoardID int,@UserID int,@CategoryID int=null,@ParentID int=null, @StyledNicks bit=null,	@FindLastRead bit = 0) as
begin
declare @tbl1 table
( ForumID int, ParentID int)
declare @tbl table
( ForumID int, ParentID int)
-- get parent forums list first
insert into @tbl1(ForumID,ParentID)
select
        b.ForumID,
        b.ParentID
    from
        [{databaseOwner}].[{objectQualifier}Category] a
        join [{databaseOwner}].[{objectQualifier}Forum] b   on b.CategoryID=a.CategoryID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x   on x.ForumID=b.ForumID
    where
        a.BoardID = @BoardID and
        ((b.Flags & 2)=0 or x.ReadAccess<>0) and
        (@CategoryID is null or a.CategoryID=@CategoryID) and
        ((@ParentID is null and b.ParentID is null) or b.ParentID=@ParentID) and
        x.UserID = @UserID
            order by
        a.SortOrder,
        b.SortOrder

-- child forums
insert into @tbl(ForumID,ParentID)
select
        b.ForumID,
        b.ParentID
    from
        [{databaseOwner}].[{objectQualifier}Category] a
        join [{databaseOwner}].[{objectQualifier}Forum] b   on b.CategoryID=a.CategoryID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x   on x.ForumID=b.ForumID
    where
        a.BoardID = @BoardID and
        ((b.Flags & 2)=0 or x.ReadAccess<>0) and
        (@CategoryID is null or a.CategoryID=@CategoryID) and
        (b.ParentID IN (SELECT ForumID FROM @tbl1)) and
        x.UserID = @UserID
        order by
        a.SortOrder,
        b.SortOrder

 insert into @tbl(ForumID,ParentID)
 select * FROM @tbl1
 -- more childrens can be added to display as a tree

        select
        a.CategoryID,
        Category		= a.Name,
        ForumID			= b.ForumID,
        Forum			= b.Name,
        b.[Description],
        b.ImageURL,
        b.Styles,
        b.ParentID,
        Topics			= [{databaseOwner}].[{objectQualifier}forum_topics](b.ForumID),
        Posts			= [{databaseOwner}].[{objectQualifier}forum_posts](b.ForumID),
        LastPosted		= t.LastPosted,
        LastMessageID	= t.LastMessageID,
        LastMessageFlags = t.LastMessageFlags,
        LastUserID		= t.LastUserID,
        LastUser		= lastUser.Name,
        LastUserDisplayName	= lastUser.DisplayName,
        LastUserSuspended = lastUser.Suspended,
        LastTopicID		= t.TopicID,
        TopicMovedID    = t.TopicMovedID,
        LastTopicName	= t.Topic,
        LastTopicStatus = t.Status,
        LastTopicStyles = t.Styles,
        b.Flags,
        Viewing			= (select count(1) from [{databaseOwner}].[{objectQualifier}Active] x  JOIN [{databaseOwner}].[{objectQualifier}User] usr  ON x.UserID = usr.UserID where x.ForumID=b.ForumID AND usr.IsActiveExcluded = 0),
        b.RemoteURL,
        ReadAccess = CONVERT(int,x.ReadAccess),
        Style = case(@StyledNicks)
            when 1 then  (select top 1 usr.[UserStyle] from [{databaseOwner}].[{objectQualifier}User] usr  where usr.UserID = t.LastUserID)
            else ''	 end,
        usr.Suspended,
        LastForumAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}ForumReadTracking] x  WHERE x.ForumID=b.ForumID AND x.UserID = @UserID)
             else ''	 end,
        LastTopicAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}TopicReadTracking] y  WHERE y.TopicID=t.TopicID AND y.UserID = @UserID)
             else ''	 end
    from
        [{databaseOwner}].[{objectQualifier}Category] a
        join [{databaseOwner}].[{objectQualifier}Forum] b  on b.CategoryID=a.CategoryID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x  on x.ForumID=b.ForumID
        left outer join [{databaseOwner}].[{objectQualifier}Topic] t  ON t.TopicID = [{databaseOwner}].[{objectQualifier}forum_lasttopic](b.ForumID,@UserID,b.LastTopicID,b.LastPosted)
        left outer join [{databaseOwner}].[{objectQualifier}User] lastUser on lastUser.UserID = t.LastUserID
    where
        (@CategoryID is null or a.CategoryID=@CategoryID) and
         x.UserID = @UserID and
        (b.ForumID IN (SELECT ForumID FROM @tbl) )
    order by
        a.SortOrder,
        b.SortOrder
end
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}forum_moderatelist](@BoardID int,@UserID int) AS
BEGIN

SELECT
        b.*,
        MessageCount  =
        (SELECT     count([{databaseOwner}].[{objectQualifier}Message].MessageID)
        FROM         [{databaseOwner}].[{objectQualifier}Message] INNER JOIN
                              [{databaseOwner}].[{objectQualifier}Topic] ON [{databaseOwner}].[{objectQualifier}Message].TopicID = [{databaseOwner}].[{objectQualifier}Topic].TopicID
        WHERE ([{databaseOwner}].[{objectQualifier}Message].IsApproved=0) and ([{databaseOwner}].[{objectQualifier}Message].IsDeleted=0) and ([{databaseOwner}].[{objectQualifier}Topic].IsDeleted  = 0) AND ([{databaseOwner}].[{objectQualifier}Topic].ForumID=b.ForumID)),

        ReportedCount	=
        (SELECT     count([{databaseOwner}].[{objectQualifier}Message].MessageID)
        FROM         [{databaseOwner}].[{objectQualifier}Message] INNER JOIN
                              [{databaseOwner}].[{objectQualifier}Topic] ON [{databaseOwner}].[{objectQualifier}Message].TopicID = [{databaseOwner}].[{objectQualifier}Topic].TopicID
        WHERE (([{databaseOwner}].[{objectQualifier}Message].Flags & 128)=128) and ([{databaseOwner}].[{objectQualifier}Message].IsDeleted=0) and ([{databaseOwner}].[{objectQualifier}Topic].IsDeleted = 0) AND ([{databaseOwner}].[{objectQualifier}Topic].ForumID=b.ForumID))
        FROM
        [{databaseOwner}].[{objectQualifier}Category] a

    JOIN [{databaseOwner}].[{objectQualifier}Forum] b ON b.CategoryID=a.CategoryID
    JOIN [{databaseOwner}].[{objectQualifier}ActiveAccess] c   ON c.ForumID=b.ForumID

    WHERE
        a.BoardID=@BoardID AND
        CONVERT(int,c.ModeratorAccess)>0 AND
        c.UserID=@UserID
    ORDER BY
        a.SortOrder,
        b.SortOrder
END
GO

create procedure [{databaseOwner}].[{objectQualifier}forum_moderators] (@BoardID int, @StyledNicks bit) as
BEGIN
        select
        ForumID = a.ForumID,
        ForumName = f.Name,
        ModeratorID = a.GroupID,
        ModeratorName = b.Name,
        ModeratorEmail = '',
		ModeratorBlockFlags = 0,
        ModeratorAvatar = '',
        ModeratorAvatarImage = CAST(0 as bit),
        ModeratorDisplayName = b.Name,
        Style = case(@StyledNicks)
            when 1 then b.Style
            else ''	 end,
        IsGroup=1,
        Suspended = null
    from
        [{databaseOwner}].[{objectQualifier}Forum] f
        INNER JOIN [{databaseOwner}].[{objectQualifier}ForumAccess] a  ON a.ForumID = f.ForumID
        INNER JOIN [{databaseOwner}].[{objectQualifier}Group] b  ON b.GroupID = a.GroupID
        INNER JOIN [{databaseOwner}].[{objectQualifier}AccessMask] c  ON c.AccessMaskID = a.AccessMaskID
    where
        b.BoardID = @BoardID and
		(c.Flags & 64)<>0
    union all
    select
        ForumID = access.ForumID,
        ForumName = f.Name,
        ModeratorID = usr.UserID,
        ModeratorName = usr.Name,
        ModeratorEmail = usr.Email,
		ModeratorBlockFlags = usr.BlockFlags,
        ModeratorAvatar = ISNULL(usr.Avatar, ''),
        ModeratorAvatarImage = CAST((select count(1) from [{databaseOwner}].[{objectQualifier}User] x where x.UserID=usr.UserID and AvatarImage is not null)as bit),
        ModeratorDisplayName = usr.DisplayName,
        Style = case(@StyledNicks)
            when 1 then  usr.UserStyle
            else ''	 end,
        IsGroup=0,
        Suspended = usr.Suspended
    from
        [{databaseOwner}].[{objectQualifier}User] usr
        INNER JOIN (
            select
                UserID				= a.UserID,
                ForumID				= x.ForumID,
                ModeratorAccess		= MAX(ModeratorAccess)
            from
                [{databaseOwner}].[{objectQualifier}vaccessfull] as x
                INNER JOIN [{databaseOwner}].[{objectQualifier}UserGroup] a  on a.UserID=x.UserID
                INNER JOIN [{databaseOwner}].[{objectQualifier}Group] b  on b.GroupID=a.GroupID
            WHERE
                b.BoardID = @BoardID and
		        ModeratorAccess <> 0
            GROUP BY a.UserID, x.ForumID
        ) access ON usr.UserID = access.UserID
        JOIN    [{databaseOwner}].[{objectQualifier}Forum] f
        ON f.ForumID = access.ForumID

        JOIN [{databaseOwner}].[{objectQualifier}Rank] r
        ON r.RankID = usr.RankID
    where
        access.ModeratorAccess<>0
    order by
        IsGroup desc,
        ModeratorName asc
END
GO

create procedure [{databaseOwner}].[{objectQualifier}forum_updatelastpost](@ForumID int) as
begin
    DECLARE @Posted DATETIME
    DECLARE @TopidID INT
    DECLARE @MessageID INT
    DECLARE @UserID INT
    DECLARE @UserName NVARCHAR(MAX)
    DECLARE @UserDisplayName NVARCHAR(MAX)

    select top 1
        @Posted = y.Posted,
        @TopidID = y.TopicID,
        @MessageID = y.MessageID,
        @UserID = y.UserID,
        @UserName = y.UserName,
        @UserDisplayName = y.UserDisplayName
    from [{databaseOwner}].[{objectQualifier}Topic] x
    join [{databaseOwner}].[{objectQualifier}Message] y on y.TopicID=x.TopicID
    where x.ForumID = @ForumID
    and (y.Flags & 24)=16
    and x.IsDeleted = 0
    order by y.Posted desc

    update [{databaseOwner}].[{objectQualifier}Forum] set
    LastPosted			= @Posted,
    LastTopicID         = @TopidID,
    LastMessageID		= @MessageID,
    LastUserID			= @UserID,
    LastUserName		= @UserName,
    LastUserDisplayName = @UserDisplayName
    where ForumID = @ForumID
end
GO

create procedure [{databaseOwner}].[{objectQualifier}forum_updatestats]
@ForumID int
as
begin
    --update Forum with forum and subforum topic values
    update  f
        set NumPosts  = isnull(t.Numposts, 0),
            NumTopics = isnull(t.Numtopics, 0)
    from    [{databaseOwner}].[{objectQualifier}Forum] as f cross apply (select sum(t.NumPosts) as Numposts,
                                                                                count(t.TopicID) as Numtopics
                                                                         from   [{databaseOwner}].[{objectQualifier}Topic] as t
                                                                                inner join
                                                                                [{databaseOwner}].[{objectQualifier}Forum] as ff
                                                                                on ff.ForumID = t.ForumID
                                                                         where  (ff.ForumID = f.ForumID
                                                                                 or ff.ParentID = f.ForumID)
                                                                                and t.IsDeleted <> 1) as t
    where   f.ForumID = isnull(@ForumID, f.ForumID);
end
go

create procedure [{databaseOwner}].[{objectQualifier}group_delete](@GroupID int) as
begin
    delete from [{databaseOwner}].[{objectQualifier}GroupMedal] where GroupID = @GroupID
    delete from [{databaseOwner}].[{objectQualifier}ForumAccess] where GroupID = @GroupID
    delete from [{databaseOwner}].[{objectQualifier}UserGroup] where GroupID = @GroupID
    delete from [{databaseOwner}].[{objectQualifier}Group] where GroupID = @GroupID
end
GO

create procedure [{databaseOwner}].[{objectQualifier}group_member](@BoardID int,@UserID int) as
begin
        select
        a.GroupID,
        a.Name,
        Member = (select count(1) from [{databaseOwner}].[{objectQualifier}UserGroup] x where x.UserID=@UserID and x.GroupID=a.GroupID)
    from
        [{databaseOwner}].[{objectQualifier}Group] a
    where
        a.BoardID=@BoardID
    order by
        a.Name
end
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}group_save](
    @GroupID		int,
    @BoardID		int,
    @Name			nvarchar(255),
    @IsAdmin		bit,
    @IsGuest		bit,
    @IsStart		bit,
    @IsModerator	bit,
    @AccessMaskID	int=null,
    @PMLimit int=null,
    @Style nvarchar(255)=null,
    @SortOrder smallint,
    @Description nvarchar(128)=null,
    @UsrSigChars int=null,
    @UsrSigBBCodes	nvarchar(255)=null,
    @UsrSigHTMLTags nvarchar(255)=null,
    @UsrAlbums int=null,
    @UsrAlbumImages int=null
) as
begin
        declare @Flags	int

    set @Flags = 0
    if @IsAdmin<>0 set @Flags = @Flags | 1
    if @IsGuest<>0 set @Flags = @Flags | 2
    if @IsStart<>0 set @Flags = @Flags | 4
    if @IsModerator<>0 set @Flags = @Flags | 8
    if @Style IS NOT NULL AND LEN(@Style) <=2 set @Style = NULL

    if @GroupID>0 begin
        update [{databaseOwner}].[{objectQualifier}Group] set
            Name = @Name,
            Flags = @Flags,
            PMLimit = @PMLimit,
            Style = @Style,
            SortOrder = @SortOrder,
            Description = @Description,
            UsrSigChars = @UsrSigChars,
            UsrSigBBCodes = @UsrSigBBCodes,
            UsrSigHTMLTags = @UsrSigHTMLTags,
            UsrAlbums = @UsrAlbums,
            UsrAlbumImages = @UsrAlbumImages
        where GroupID = @GroupID
    end
    else begin
        insert into [{databaseOwner}].[{objectQualifier}Group](Name,BoardID,Flags,PMLimit,Style, SortOrder,Description,UsrSigChars,UsrSigBBCodes,UsrSigHTMLTags,UsrAlbums,UsrAlbumImages)
        values(@Name,@BoardID,@Flags,@PMLimit,@Style,@SortOrder,@Description,@UsrSigChars,@UsrSigBBCodes,@UsrSigHTMLTags,@UsrAlbums,@UsrAlbumImages);
        set @GroupID = SCOPE_IDENTITY()
        insert into [{databaseOwner}].[{objectQualifier}ForumAccess](GroupID,ForumID,AccessMaskID)
        select @GroupID,a.ForumID,@AccessMaskID from [{databaseOwner}].[{objectQualifier}Forum] a join [{databaseOwner}].[{objectQualifier}Category] b on b.CategoryID=a.CategoryID where b.BoardID=@BoardID
    end
    -- group styles override rank styles
    IF @Style IS NOT NULL AND len(@Style) > 2
      BEGIN
      EXEC [{databaseOwner}].[{objectQualifier}user_savestyle] @GroupID,null
      END



    select GroupID = @GroupID
end
GO

create procedure [{databaseOwner}].[{objectQualifier}message_approve](@MessageID int) as begin

    declare	@UserID		int
    declare	@ForumID	int
    declare	@TopicID	int

    declare	@Flags	    int
    declare @Posted		datetime
    declare	@UserName	nvarchar(255)
    declare	@UserDisplayName	nvarchar(255)
    select
        @UserID = a.UserID,
        @TopicID = a.TopicID,
        @ForumID = b.ForumID,
        @Posted = a.Posted,
        @UserName = a.UserName,
        @UserDisplayName = a.UserDisplayName,
        @Flags	= a.Flags
    from
        [{databaseOwner}].[{objectQualifier}Message] a
        inner join [{databaseOwner}].[{objectQualifier}Topic] b on b.TopicID=a.TopicID
    where
        a.MessageID = @MessageID

    -- update Message table, set meesage flag to approved
    update [{databaseOwner}].[{objectQualifier}Message] set Flags = Flags | 16 where MessageID = @MessageID

    -- update User table to increase postcount
    if exists(select top 1 1 from [{databaseOwner}].[{objectQualifier}Forum] where ForumID=@ForumID and (Flags & 4)=0)
    begin
        update [{databaseOwner}].[{objectQualifier}User] set NumPosts = NumPosts + 1 where UserID = @UserID
        -- upgrade user, i.e. promote rank if conditions allow it
        exec [{databaseOwner}].[{objectQualifier}user_upgrade] @UserID
    end

    -- update Forum table with last topic/post info
    update [{databaseOwner}].[{objectQualifier}Forum] set
        LastPosted = @Posted,
        LastTopicID = @TopicID,
        LastMessageID = @MessageID,
        LastUserID = @UserID,
        LastUserName = @UserName,
        LastUserDisplayName = @UserDisplayName
    where ForumID = @ForumID

    -- update Topic table with info about last post in topic
    update [{databaseOwner}].[{objectQualifier}Topic] set
        LastPosted = @Posted,
        LastMessageID = @MessageID,
        LastUserID = @UserID,
        LastUserName = @UserName,
        LastUserDisplayName = @UserDisplayName,
        LastMessageFlags = @Flags | 16,
        NumPosts = (select count(1) from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and x.IsApproved = 1 and x.IsDeleted = 0)
    where TopicID = @TopicID

    -- update forum stats
    exec [{databaseOwner}].[{objectQualifier}forum_updatestats] @ForumID
end
GO

create procedure [{databaseOwner}].[{objectQualifier}message_delete](@MessageID int, @EraseMessage bit = 0) as
begin

    declare @TopicID		int
    declare @ForumID		int
    declare @MessageCount	int
    declare @LastMessageID	int
    declare @UserID			int
	declare @ReplyToID      int

    -- Find TopicID and ForumID
    select 
	        @TopicID=b.TopicID,
			@ForumID=b.ForumID,
			@UserID = a.UserID
        from
            [{databaseOwner}].[{objectQualifier}Message] a
            inner join [{databaseOwner}].[{objectQualifier}Topic] b on b.TopicID=a.TopicID
        where
            a.MessageID=@MessageID


    -- Update LastMessageID in Topic
    update [{databaseOwner}].[{objectQualifier}Topic] set
        LastPosted = null,
        LastMessageID = null,
        LastUserID = null,
        LastUserName = null,
        LastUserDisplayName = null,
        LastMessageFlags = null
    where LastMessageID = @MessageID

    -- Update LastMessageID in Forum
    update [{databaseOwner}].[{objectQualifier}Forum] set
        LastPosted = null,
        LastTopicID = null,
        LastMessageID = null,
        LastUserID = null,
        LastUserName = null,
        LastUserDisplayName = null
    where LastMessageID = @MessageID

    -- should it be physically deleter or not?
    if (@EraseMessage = 1) begin
        delete [{databaseOwner}].[{objectQualifier}Attachment] where MessageID = @MessageID
		delete [{databaseOwner}].[{objectQualifier}Activity] where MessageID = @MessageID
        delete [{databaseOwner}].[{objectQualifier}MessageReportedAudit] where MessageID = @MessageID
        delete [{databaseOwner}].[{objectQualifier}MessageReported] where MessageID = @MessageID
        --delete thanks related to this message
        delete [{databaseOwner}].[{objectQualifier}Thanks] where MessageID = @MessageID
        delete [{databaseOwner}].[{objectQualifier}MessageHistory] where MessageID = @MessageID
        -- update message positions inside the topic
		declare @Posted datetime = (select Posted from [{databaseOwner}].[{objectQualifier}Message] where MessageID = @MessageID)

		update [{databaseOwner}].[{objectQualifier}Message]
		    set Position = Position-1
		where
		    TopicID = @TopicID and Posted > @Posted and MessageID != @MessageID

		-- update ReplyTo
		set	@ReplyToID = (select
		                      MessageID
						  from
						      [{databaseOwner}].[{objectQualifier}Message]
                          where
						      TopicID = @TopicID and Position = 0 and MessageID != @MessageID
					     )

		update
		    [{databaseOwner}].[{objectQualifier}Message]
	        set ReplyTo = @ReplyToID
        where
		    TopicID = @TopicID and ReplyTo = @MessageID

	    -- fix Reply To if equal with MessageID
		update
		    [{databaseOwner}].[{objectQualifier}Message]
	        set ReplyTo = NULL
        where
		    TopicID = @TopicID and MessageID = @ReplyToID

	    -- finally delete the message we want to delete
        delete
		    [{databaseOwner}].[{objectQualifier}Message]
		where
		    MessageID = @MessageID

    end
    else begin
        -- "Delete" it only by setting deleted flag message
        update [{databaseOwner}].[{objectQualifier}Message] set Flags = Flags | 8 where MessageID = @MessageID
    end

    -- update user post count
    if exists(select top 1 1 from [{databaseOwner}].[{objectQualifier}Forum] where ForumID=@ForumID and (Flags & 4)=0)
    begin
	     UPDATE [{databaseOwner}].[{objectQualifier}User] SET NumPosts = (SELECT count(MessageID) FROM [{databaseOwner}].[{objectQualifier}Message] WHERE UserID = @UserID AND IsDeleted = 0 AND IsApproved = 1) WHERE UserID = @UserID
    end

    -- Delete topic if there are no more messages
    select @MessageCount = count(1) from [{databaseOwner}].[{objectQualifier}Message] where TopicID = @TopicID and IsDeleted=0
    if @MessageCount=0 exec [{databaseOwner}].[{objectQualifier}topic_delete] @TopicID, 1, @EraseMessage

    -- update lastpost
    exec [{databaseOwner}].[{objectQualifier}topic_updatelastpost] @ForumID,@TopicID
    exec [{databaseOwner}].[{objectQualifier}forum_updatestats] @ForumID

    -- update topic numposts
    update [{databaseOwner}].[{objectQualifier}Topic] set
        NumPosts = (select count(1) from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and x.IsApproved = 1 and x.IsDeleted = 0)
    where TopicID = @TopicID
end
GO

create procedure [{databaseOwner}].[{objectQualifier}message_findunread](
@TopicID int,
@MessageID int,
@LastRead datetime,
@MinDateTime datetime,
@ShowDeleted bit = 0,
@AuthorUserID int) as
begin
   declare @MessagePosition int

   if (@MessageID > 0)
   begin
   select top 1 @MessagePosition = CONVERT(int,RowNum), @MessageID = tbl.MessageID  from
   (
   select ROW_NUMBER() OVER ( order by Posted desc) as RowNum, m.MessageID
   from [{databaseOwner}].[{objectQualifier}Message] m
   where m.TopicID = @TopicID
        AND m.IsApproved = 1
        AND (@ShowDeleted = 1 OR m.IsDeleted = 0 OR (@AuthorUserID > 0 AND m.UserID = @AuthorUserID))
   ) as tbl
   where tbl.MessageID = @MessageID
   order by tbl.RowNum ASC;
   end
-- a message with the id was not found or we are looking for first unread or last post
  if (@MessageID <= 0)
   begin
   -- if value > yaf db min value (1-1-1903) we are looking for first unread
   if (@LastRead > @MinDateTime)
   begin
   select top 1 @MessagePosition = CONVERT(int,RowNum), @MessageID = tbl.MessageID  from
   (
   select ROW_NUMBER() OVER ( order by m.Posted asc) as RowNum, m.MessageID, m.Posted
   from [{databaseOwner}].[{objectQualifier}Message] m
   where m.TopicID = @TopicID
        AND m.IsApproved = 1
        AND (@ShowDeleted = 1 OR m.IsDeleted = 0 OR (@AuthorUserID > 0 AND m.UserID = @AuthorUserID))
   ) as tbl
   where tbl.Posted > @LastRead
   order by tbl.RowNum ASC;
   end
   -- if first unread was not found or we looking for last posted
   if (@LastRead < @MinDateTime OR @MessagePosition IS NULL)
   begin
        select top 1 @MessageID = m.MessageID, @MessagePosition = 1
    from
        [{databaseOwner}].[{objectQualifier}Message] m
    where
        m.TopicID = @TopicID
        AND m.IsApproved = 1
       AND (@ShowDeleted = 1 OR m.IsDeleted = 0 OR (@AuthorUserID > 0 AND m.UserID = @AuthorUserID))
    order by
        m.Posted DESC;
    end

	 select top 1 @MessagePosition = CONVERT(int,RowNum), @MessageID = tbl.MessageID  from
   (
   select ROW_NUMBER() OVER ( order by Posted desc) as RowNum, m.MessageID
   from [{databaseOwner}].[{objectQualifier}Message] m
   where m.TopicID = @TopicID
        AND m.IsApproved = 1
        AND (@ShowDeleted = 1 OR m.IsDeleted = 0 OR (@AuthorUserID > 0 AND m.UserID = @AuthorUserID))
   ) as tbl
   where tbl.MessageID = @MessageID
   order by tbl.RowNum ASC;
end

select @MessageID as MessageID, @MessagePosition as MessagePosition;
end
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}message_listreported](@ForumID int) AS
BEGIN
        SELECT
        a.*,
        OriginalMessage = b.[Message],
        b.[Flags],
        b.[IsModeratorChanged],
        UserName	= IsNull(b.UserName,d.Name),
        UserDisplayName	= IsNull(b.UserDisplayName,d.DisplayName),
        UserID = b.UserID,
        d.Suspended,
        d.UserStyle,
        Posted		= b.Posted,
        TopicID = b.TopicID,
        Topic		= c.Topic,
        NumberOfReports = (SELECT count(LogID) FROM [{databaseOwner}].[{objectQualifier}MessageReportedAudit] WHERE [{databaseOwner}].[{objectQualifier}MessageReportedAudit].MessageID = a.MessageID)
    FROM
        [{databaseOwner}].[{objectQualifier}MessageReported] a
    INNER JOIN
        [{databaseOwner}].[{objectQualifier}Message] b ON a.MessageID = b.MessageID
    INNER JOIN
        [{databaseOwner}].[{objectQualifier}Topic] c ON b.TopicID = c.TopicID
    INNER JOIN
        [{databaseOwner}].[{objectQualifier}User] d ON b.UserID = d.UserID
    WHERE
        c.ForumID = @ForumID and
        (c.Flags & 16)=0 and
        b.IsDeleted=0 and
        c.IsDeleted=0 and
        (b.Flags & 128)=128
    ORDER BY
        b.TopicID DESC, b.Posted DESC
END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}message_listreporters](@MessageID int, @UserID int = null) AS
BEGIN
    IF ( @UserID > 0 )
    BEGIN
    SELECT 
    b.UserID, UserName = a.Name,UserDisplayName = a.DisplayName, b.ReportedNumber, b.ReportText,
    a.Suspended, 
    a.UserStyle
    FROM [{databaseOwner}].[{objectQualifier}User] a,
    [{databaseOwner}].[{objectQualifier}MessageReportedAudit] b
    WHERE   a.UserID = b.UserID  AND b.MessageID = @MessageID AND b.UserID = @UserID
    END
    ELSE
    BEGIN
    SELECT 
    b.UserID, UserName = a.Name,UserDisplayName = a.DisplayName, b.ReportedNumber, b.ReportText,
    a.Suspended, 
    a.UserStyle
    FROM [{databaseOwner}].[{objectQualifier}User] a,
    [{databaseOwner}].[{objectQualifier}MessageReportedAudit] b
    WHERE   a.UserID = b.UserID  AND b.MessageID = @MessageID
    END


END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}message_report](@MessageID int, @ReporterID int, @ReportedDate datetime, @ReportText nvarchar(4000),@UTCTIMESTAMP datetime) AS
BEGIN
    IF @ReportText IS NULL SET @ReportText = '';
    IF NOT exists(SELECT MessageID FROM [{databaseOwner}].[{objectQualifier}MessageReported] WHERE MessageID=@MessageID)
    BEGIN
        INSERT INTO [{databaseOwner}].[{objectQualifier}MessageReported](MessageID, [Message])
        SELECT
            a.MessageID,
            a.[Message]
        FROM
            [{databaseOwner}].[{objectQualifier}Message] a
        WHERE
            a.MessageID = @MessageID
    END
    IF NOT exists(SELECT MessageID from [{databaseOwner}].[{objectQualifier}MessageReportedAudit] WHERE MessageID=@MessageID AND UserID=@ReporterID)
        INSERT INTO [{databaseOwner}].[{objectQualifier}MessageReportedAudit](MessageID,UserID,Reported,ReportText) VALUES (@MessageID,@ReporterID,@ReportedDate, CONVERT(varchar,@UTCTIMESTAMP )+ '??' + @ReportText)
    ELSE
        UPDATE [{databaseOwner}].[{objectQualifier}MessageReportedAudit] SET ReportedNumber = ( CASE WHEN ReportedNumber < 2147483647 THEN  ReportedNumber  + 1 ELSE ReportedNumber END ), Reported = @ReportedDate, ReportText = (CASE WHEN (LEN(ReportText) + LEN(@ReportText) + 255 < 4000)  THEN  ReportText + '|' + CONVERT(varchar(36),@UTCTIMESTAMP )+ '??' +  @ReportText ELSE ReportText END) WHERE MessageID=@MessageID AND UserID=@ReporterID


    -- update Message table to set message with flag Reported
    UPDATE [{databaseOwner}].[{objectQualifier}Message] SET Flags = Flags | 128 WHERE MessageID = @MessageID

END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}message_reportresolve](@MessageFlag int, @MessageID int, @UserID int,@UTCTIMESTAMP datetime) AS
BEGIN

    UPDATE [{databaseOwner}].[{objectQualifier}MessageReported]
    SET Resolved = 1, ResolvedBy = @UserID, ResolvedDate = @UTCTIMESTAMP
    WHERE MessageID = @MessageID;

    /* Remove Flag */
    UPDATE [{databaseOwner}].[{objectQualifier}Message]
    SET Flags = Flags & (~POWER(2, @MessageFlag))
    WHERE MessageID = @MessageID;
END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}message_save](
    @TopicID		int,
    @UserID			int,
    @Message		ntext,
    @UserName		nvarchar(255)=null,
    @IP				varchar(39),
    @Posted			datetime=null,
    @ReplyTo		int,
    @BlogPostID		nvarchar(50) = null,
    @ExternalMessageId nvarchar(255) = null,
    @ReferenceMessageId nvarchar(255) = null,
    @Flags			int,
    @UTCTIMESTAMP datetime,
    @MessageID		int output
)
AS
BEGIN
        DECLARE @ForumID INT, @ForumFlags INT, @Position INT, @Indent INT, @OverrideDisplayName BIT, @ReplaceName nvarchar(255)

    IF @Posted IS NULL
        SET @Posted = @UTCTIMESTAMP

    SELECT @ForumID = x.ForumID, @ForumFlags = y.Flags
    FROM
        [{databaseOwner}].[{objectQualifier}Topic] x
    INNER JOIN
        [{databaseOwner}].[{objectQualifier}Forum] y ON y.ForumID=x.ForumID
    WHERE x.TopicID = @TopicID

    IF @ReplyTo IS NULL
            SELECT @Position = 0, @Indent = 0 -- New thread

    ELSE IF @ReplyTo<0
        -- Find post to reply to AND indent of this post
        SELECT TOP 1 @ReplyTo = MessageID, @Indent = Indent+1
        FROM [{databaseOwner}].[{objectQualifier}Message]
        WHERE TopicID = @TopicID AND ReplyTo IS NULL
        ORDER BY Posted

    ELSE
        -- Got reply, find indent of this post
            SELECT @Indent=Indent+1
            FROM [{databaseOwner}].[{objectQualifier}Message]
            WHERE MessageID=@ReplyTo

    -- Find position
    IF @ReplyTo IS NOT NULL
    BEGIN
        DECLARE @temp INT

        SELECT @temp=ReplyTo,@Position=Position FROM [{databaseOwner}].[{objectQualifier}Message] WHERE MessageID=@ReplyTo

        IF @temp IS NULL
            -- We are replying to first post
            SELECT @Position=MAX(Position)+1 FROM [{databaseOwner}].[{objectQualifier}Message] WHERE TopicID=@TopicID

        ELSE
            -- Last position of replies to parent post
            SELECT @Position=MIN(Position) FROM [{databaseOwner}].[{objectQualifier}Message] WHERE ReplyTo=@temp AND Position>@Position

        -- No replies, THEN USE parent post's position+1
        IF @Position IS NULL
            SELECT @Position=Position+1 FROM [{databaseOwner}].[{objectQualifier}Message] WHERE MessageID=@ReplyTo
        -- Increase position of posts after this

        UPDATE [{databaseOwner}].[{objectQualifier}Message] SET Position=Position+1 WHERE TopicID=@TopicID AND Position>=@Position
    END

	-- Add points to Users total reputation points
 	UPDATE [{databaseOwner}].[{objectQualifier}User] SET Points = Points + 3 WHERE UserID = @UserID

	-- this check is for guest user only to not override replace name
    if (SELECT Name FROM [{databaseOwner}].[{objectQualifier}User] WHERE UserID = @UserID) != @UserName
    begin
    SET @OverrideDisplayName = 1
    end
    SET @ReplaceName = (CASE WHEN @OverrideDisplayName = 1 THEN @UserName ELSE (SELECT DisplayName FROM [{databaseOwner}].[{objectQualifier}User] WHERE UserID = @UserID) END);
    INSERT [{databaseOwner}].[{objectQualifier}Message] ( UserID, [Message], TopicID, Posted, UserName, UserDisplayName, IP, ReplyTo, Position, Indent, Flags, BlogPostID, ExternalMessageId, ReferenceMessageId)
    VALUES ( @UserID, @Message, @TopicID, @Posted, @UserName,@ReplaceName, @IP, @ReplyTo, @Position, @Indent, @Flags & ~16, @BlogPostID, @ExternalMessageId, @ReferenceMessageId)

    SET @MessageID = SCOPE_IDENTITY()

    IF ((@Flags & 16) = 16)
        EXEC [{databaseOwner}].[{objectQualifier}message_approve] @MessageID
END

GO

CREATE procedure [{databaseOwner}].[{objectQualifier}message_update](
@MessageID int,
@Priority int,
@Subject nvarchar(100),
@Description nvarchar(255),
@Status nvarchar(255),
@Styles nvarchar(255),
@Flags int,
@Message nvarchar(max),
@Reason nvarchar(100),
@EditedBy int,
@IsModeratorChanged bit,
@OverrideApproval bit = null,
@OriginalMessage nvarchar(max),
@CurrentUtcTimestamp datetime) as
begin
        declare @TopicID	int
    declare	@ForumFlags	int

    set @Flags = @Flags & ~16

    select
        @TopicID	= a.TopicID,
        @ForumFlags	= c.Flags
    from
        [{databaseOwner}].[{objectQualifier}Message] a
        inner join [{databaseOwner}].[{objectQualifier}Topic] b on b.TopicID = a.TopicID
        inner join [{databaseOwner}].[{objectQualifier}Forum] c on c.ForumID = b.ForumID
    where
        a.MessageID = @MessageID

    if (@OverrideApproval = 1 OR (@ForumFlags & 8)=0) set @Flags = @Flags | 16

	-- save original message in the history if this is the first edit
	if not exists(select 1 from [{databaseOwner}].[{objectQualifier}MessageHistory] where MessageID=@MessageID)
	  begin
	    insert into [{databaseOwner}].[{objectQualifier}MessageHistory] (MessageID,
            [Message],
            IP,
            Edited,
            EditedBy,
            EditReason,
            IsModeratorChanged,
            Flags)
            select MessageID,
			       OriginalMessage=@OriginalMessage,
				   IP,
				   Posted,
				   UserID,
				   NULL,
				   IsModeratorChanged,
				   Flags
		    from [{databaseOwner}].[{objectQualifier}Message] where MessageID = @MessageID
	  end
	else
	 begin
	     -- insert current message variant - use OriginalMessage in future
        insert into [{databaseOwner}].[{objectQualifier}MessageHistory]
        (MessageID,
            [Message],
            IP,
            Edited,
            EditedBy,
            EditReason,
            IsModeratorChanged,
            Flags)
        select
        MessageID, OriginalMessage=@OriginalMessage, IP , @CurrentUtcTimestamp, IsNull(EditedBy,UserID), EditReason, IsModeratorChanged, Flags
        from [{databaseOwner}].[{objectQualifier}Message] where MessageID = @MessageID
	 end




    update [{databaseOwner}].[{objectQualifier}Message] set
        [Message] = @Message,
        Edited = @CurrentUtcTimestamp,
        EditedBy = @EditedBy,
        Flags = @Flags,
        IsModeratorChanged  = @IsModeratorChanged,
                EditReason = @Reason
    where
        MessageID = @MessageID

    if @Priority is not null begin
        update [{databaseOwner}].[{objectQualifier}Topic] set
            Priority = @Priority
        where
            TopicID = @TopicID
    end

    if not @Subject = '' and @Subject is not null begin
        update [{databaseOwner}].[{objectQualifier}Topic] set
            Topic = @Subject,
            [Description] = @Description,
            [Status] = @Status,
            [Styles] = @Styles
        where
            TopicID = @TopicID
    end

    -- If forum is moderated, make sure last post pointers are correct
    if (@ForumFlags & 8)<>0 exec [{databaseOwner}].[{objectQualifier}topic_updatelastpost]
end
GO

create procedure [{databaseOwner}].[{objectQualifier}nntpforum_update](@NntpForumID int,@LastMessageNo int,@UserID int,@UTCTIMESTAMP datetime) as
begin
        declare	@ForumID	int

    select @ForumID=ForumID from [{databaseOwner}].[{objectQualifier}NntpForum] where NntpForumID=@NntpForumID

    update [{databaseOwner}].[{objectQualifier}NntpForum] set
        LastMessageNo = @LastMessageNo,
        LastUpdate = @UTCTIMESTAMP
    where NntpForumID = @NntpForumID

    update [{databaseOwner}].[{objectQualifier}Topic] set
        NumPosts = (select count(1) from [{databaseOwner}].[{objectQualifier}message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and x.IsApproved = 1 and x.IsDeleted = 0)
    where ForumID=@ForumID

    --exec [{databaseOwner}].[{objectQualifier}user_upgrade] @UserID
    exec [{databaseOwner}].[{objectQualifier}forum_updatestats] @ForumID
    -- exec [{databaseOwner}].[{objectQualifier}topic_updatelastpost] @ForumID,null
end
GO

create procedure [{databaseOwner}].[{objectQualifier}nntptopic_savemessage](
    @NntpForumID	int,
    @Topic 			nvarchar(100),
    @Body 			ntext,
    @UserID 		int,
    @UserName		nvarchar(255),
    @IP				varchar(39),
    @Posted			datetime,
    @ExternalMessageId	nvarchar(255),
    @ReferenceMessageId nvarchar(255) = null,
    @UTCTIMESTAMP datetime
) as
begin
    declare	@ForumID	int
    declare @TopicID	int
    declare	@MessageID	int
    declare @ReplyTo	int

    SET @TopicID = NULL
    SET @ReplyTo = NULL

    select @ForumID = ForumID from [{databaseOwner}].[{objectQualifier}NntpForum] where NntpForumID=@NntpForumID

    if exists(select 1 from [{databaseOwner}].[{objectQualifier}Message] where ExternalMessageId = @ReferenceMessageId)
    begin
        -- referenced message exists
        select @TopicID = TopicID, @ReplyTo = MessageID from [{databaseOwner}].[{objectQualifier}Message] where ExternalMessageId = @ReferenceMessageId
    end else
    if not exists(select 1 from [{databaseOwner}].[{objectQualifier}Message] where ExternalMessageId = @ExternalMessageId)
    begin
        if (@ReferenceMessageId IS NULL)
        begin
            -- thread doesn't exists
            insert into [{databaseOwner}].[{objectQualifier}Topic](ForumID,UserID,UserName, UserDisplayName,Posted,Topic,[Views],Priority,NumPosts)
            values (@ForumID,@UserID,@UserName, @UserName,@Posted,@Topic,0,0,0)
            set @TopicID=SCOPE_IDENTITY()

            insert into [{databaseOwner}].[{objectQualifier}NntpTopic](NntpForumID,Thread,TopicID)
            values (@NntpForumID,'',@TopicID)
        end
    end

    IF @TopicID IS NOT NULL
    BEGIN
        exec [{databaseOwner}].[{objectQualifier}message_save]  @TopicID, @UserID, @Body, @UserName, @IP, @Posted, @ReplyTo, NULL, @ExternalMessageId, @ReferenceMessageId, 17,@UTCTIMESTAMP, @MessageID OUTPUT
    END
end
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}pageaccess](
    @BoardID int,
    @UserID	int,
    @IsGuest bit,
    @UTCTIMESTAMP datetime
) as
begin
    -- ensure that access right are in place
        if not exists (select top 1
            UserID
            from [{databaseOwner}].[{objectQualifier}ActiveAccess]
            where UserID = @UserID )
            begin
            insert into [{databaseOwner}].[{objectQualifier}ActiveAccess](
            UserID,
            BoardID,
            ForumID,
            IsAdmin,
            IsForumModerator,
            IsModerator,
            IsGuestX,
            LastActive,
            ReadAccess,
            PostAccess,
            ReplyAccess,
            PriorityAccess,
            PollAccess,
            VoteAccess,
            ModeratorAccess,
            EditAccess,
            DeleteAccess,
            UploadAccess,
            DownloadAccess)
            select
            UserID,
            @BoardID,
            ForumID,
            IsAdmin,
            IsForumModerator,
            IsModerator,
            @IsGuest,
            @UTCTIMESTAMP,
            ReadAccess,
            (CONVERT([bit],sign([PostAccess]&(2)),(0))),
            ReplyAccess,
            PriorityAccess,
            PollAccess,
            VoteAccess,
            ModeratorAccess,
            EditAccess,
            DeleteAccess,
            UploadAccess,
            DownloadAccess
            from [{databaseOwner}].[{objectQualifier}vaccess]
            where UserID = @UserID
            end
    -- return information
    select
        x.*
    from
     [{databaseOwner}].[{objectQualifier}ActiveAccess] x
    where
        x.UserID = @UserID
end
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}pageload](
    @SessionID	nvarchar(24),
    @BoardID	int,
    @UserKey	nvarchar(64),
    @IP			varchar(39),
    @Location	nvarchar(255),
    @ForumPage  nvarchar(255) = null,
    @Browser	nvarchar(50),
    @Platform	nvarchar(50),
    @CategoryID	int = null,
    @ForumID	int = null,
    @TopicID	int = null,
    @MessageID	int = null,
    @IsCrawler	bit = 0,
    @IsMobileDevice	bit = 0,
    @DontTrack	bit = 0,
    @UTCTIMESTAMP datetime
) as
begin
    declare @UserID			int
    declare @UserBoardID	int
    declare @IsGuest		tinyint
    declare @rowcount		int
    declare @PreviousVisit	datetime
    declare @ActiveUpdate   tinyint
    declare @ActiveFlags	int
    declare @GuestID        int

    set implicit_transactions off
    -- set IsActiveNow ActiveFlag - it's a default
    set @ActiveFlags = 1;

      -- find a guest id should do it every time to be sure that guest access rights are in ActiveAccess table
    select top 1 @GuestID = UserID from [{databaseOwner}].[{objectQualifier}User]  where BoardID=@BoardID and (Flags & 4)=4 ORDER BY Joined DESC
        set @rowcount=@@rowcount
        if (@rowcount > 1)
        begin
            raiserror('Found %d possible guest users. There should be one and only one user marked as guest.',16,1,@rowcount)
            end
        if (@rowcount = 0)
        begin
            raiserror('No candidates for a guest were found for the board %d.',16,1,@BoardID)
            end



    if @UserKey is null
    begin
    -- this is a guest
        SET @UserID = @GuestID
        set @IsGuest = 1
        -- set IsGuest ActiveFlag  1 | 2
        set @ActiveFlags = 3
        set @UserBoardID = @BoardID
        -- crawlers are always guests
        if	@IsCrawler = 1
            begin
                -- set IsCrawler ActiveFlag
                set @ActiveFlags =  @ActiveFlags | 8
            end
    end
    else
    begin
        select @UserID = UserID, @UserBoardID = BoardID from [{databaseOwner}].[{objectQualifier}User]  where BoardID=@BoardID and ProviderUserKey=@UserKey
        set @IsGuest = 0
        -- make sure that registered users are not crawlers
        set @IsCrawler = 0
        -- set IsRegistered ActiveFlag
        set @ActiveFlags = @ActiveFlags | 4
    end

    -- Check valid ForumID
    if @ForumID is not null and not exists(select 1 from [{databaseOwner}].[{objectQualifier}Forum] where ForumID=@ForumID) begin
        set @ForumID = null
    end
    -- Check valid CategoryID
    if @CategoryID is not null and not exists(select 1 from [{databaseOwner}].[{objectQualifier}Category] where CategoryID=@CategoryID) begin
        set @CategoryID = null
    end
    -- Check valid MessageID
    if @MessageID is not null and not exists(select 1 from [{databaseOwner}].[{objectQualifier}Message] where MessageID=@MessageID) begin
        set @MessageID = null
    end
    -- Check valid TopicID
    if @TopicID is not null and not exists(select 1 from [{databaseOwner}].[{objectQualifier}Topic] where TopicID=@TopicID) begin
        set @TopicID = null
    end

    -- find missing ForumID/TopicID
    if @MessageID is not null begin
        select
            @CategoryID = c.CategoryID,
            @ForumID = b.ForumID,
            @TopicID = b.TopicID
        from
            [{databaseOwner}].[{objectQualifier}Message] a
            inner join [{databaseOwner}].[{objectQualifier}Topic] b on b.TopicID = a.TopicID
            inner join [{databaseOwner}].[{objectQualifier}Forum] c on c.ForumID = b.ForumID
            inner join [{databaseOwner}].[{objectQualifier}Category] d on d.CategoryID = c.CategoryID
        where
            a.MessageID = @MessageID and
            d.BoardID = @BoardID
    end
    else if @TopicID is not null begin
        select
            @CategoryID = b.CategoryID,
            @ForumID = a.ForumID
        from
            [{databaseOwner}].[{objectQualifier}Topic] a
            inner join [{databaseOwner}].[{objectQualifier}Forum] b on b.ForumID = a.ForumID
            inner join [{databaseOwner}].[{objectQualifier}Category] c on c.CategoryID = b.CategoryID
        where
            a.TopicID = @TopicID and
            c.BoardID = @BoardID
    end
    else if @ForumID is not null begin
        select
            @CategoryID = a.CategoryID
        from
            [{databaseOwner}].[{objectQualifier}Forum] a
            inner join [{databaseOwner}].[{objectQualifier}Category] b on b.CategoryID = a.CategoryID
        where
            a.ForumID = @ForumID and
            b.BoardID = @BoardID
    end



    -- update active access
    -- ensure that access right are in place
        if not exists (select top 1
            UserID
            from [{databaseOwner}].[{objectQualifier}ActiveAccess]
            where UserID = @UserID )
            begin
            insert into [{databaseOwner}].[{objectQualifier}ActiveAccess](
            UserID,
            BoardID,
            ForumID,
            IsAdmin,
            IsForumModerator,
            IsModerator,
            IsGuestX,
            LastActive,
            ReadAccess,
            PostAccess,
            ReplyAccess,
            PriorityAccess,
            PollAccess,
            VoteAccess,
            ModeratorAccess,
            EditAccess,
            DeleteAccess,
            UploadAccess,
            DownloadAccess)
            select
            UserID,
            @BoardID,
            ForumID,
            IsAdmin,
            IsForumModerator,
            IsModerator,
            @IsGuest,
            @UTCTIMESTAMP,
            ReadAccess,
            (CONVERT([bit],sign([PostAccess]&(2)),(0))),
            ReplyAccess,
            PriorityAccess,
            PollAccess,
            VoteAccess,
            ModeratorAccess,
            EditAccess,
            DeleteAccess,
            UploadAccess,
            DownloadAccess
            from [{databaseOwner}].[{objectQualifier}vaccess]
            where UserID = @UserID
            end

                -- ensure that guest access right are in place
        if @UserID != @GuestID and not exists (select top 1
            UserID
            from [{databaseOwner}].[{objectQualifier}ActiveAccess]
            where UserID = @GuestID )
            begin
            insert into [{databaseOwner}].[{objectQualifier}ActiveAccess](
            UserID,
            BoardID,
            ForumID,
            IsAdmin,
            IsForumModerator,
            IsModerator,
            IsGuestX,
            LastActive,
            ReadAccess,
            PostAccess,
            ReplyAccess,
            PriorityAccess,
            PollAccess,
            VoteAccess,
            ModeratorAccess,
            EditAccess,
            DeleteAccess,
            UploadAccess,
            DownloadAccess)
            select
            UserID,
            @BoardID,
            ForumID,
            IsAdmin,
            IsForumModerator,
            IsModerator,
            @IsGuest,
            @UTCTIMESTAMP,
            ReadAccess,
            (CONVERT([bit],sign([PostAccess]&(2)),(0))),
            ReplyAccess,
            PriorityAccess,
            PollAccess,
            VoteAccess,
            ModeratorAccess,
            EditAccess,
            DeleteAccess,
            UploadAccess,
            DownloadAccess
            from [{databaseOwner}].[{objectQualifier}vaccess]
            where UserID = @GuestID
            end

        if exists (select top 1
            UserID
            from [{databaseOwner}].[{objectQualifier}ActiveAccess]
            where UserID = @UserID and ForumID= ISNULL(@ForumID,0) and (ISNULL(@ForumID,0) = 0 OR ReadAccess = 1))
            begin
                 -- verify that there's not the sane session for other board and drop it if required. Test code for portals with many boards
     delete from [{databaseOwner}].[{objectQualifier}Active] where (SessionID=@SessionID  and (BoardID <> @BoardID or UserID <> @UserID))
    -- get previous visit
    if  @IsGuest = 0	 begin
        select @PreviousVisit = LastVisit from [{databaseOwner}].[{objectQualifier}User] where UserID = @UserID
    end

    -- update last visit
    update [{databaseOwner}].[{objectQualifier}User] set
        LastVisit = @UTCTIMESTAMP,
        IP = @IP
    where UserID = @UserID

    if @DontTrack != 1 and @UserID is not null and @UserBoardID=@BoardID begin
      if exists(select 1 from [{databaseOwner}].[{objectQualifier}Active] where (SessionID=@SessionID OR ( Browser = @Browser AND (Flags & 8) = 8 )) and BoardID=@BoardID)
        begin
          -- user is not a crawler - use his session id
          if @IsCrawler <> 1
          begin
            update [{databaseOwner}].[{objectQualifier}Active] set
                UserID = @UserID,
                IP = @IP,
                LastActive = @UTCTIMESTAMP ,
                Location = @Location,
                ForumID = @ForumID,
                TopicID = @TopicID,
                Browser = @Browser,
                [Platform] = @Platform,
                ForumPage = @ForumPage,
                Flags = @ActiveFlags
            where SessionID = @SessionID AND BoardID=@BoardID
                -- cache will be updated every time set @ActiveUpdate = 1
            end
            else
            begin
            -- search crawler by other parameters then session id
            update [{databaseOwner}].[{objectQualifier}Active] set
                UserID = @UserID,
                IP = @IP,
                LastActive = @UTCTIMESTAMP ,
                Location = @Location,
                ForumID = @ForumID,
                TopicID = @TopicID,
                Browser = @Browser,
                [Platform] = @Platform,
                ForumPage = @ForumPage,
                Flags = @ActiveFlags
            where Browser = @Browser AND IP = @IP AND BoardID=@BoardID
            -- trace crawler: the cache is reset every time crawler moves to next page ? Disabled as cache reset will overload server
                -- set @ActiveUpdate = 1
            end
        end
        else
        begin
             -- we set @ActiveFlags ready flags
            insert into [{databaseOwner}].[{objectQualifier}Active](
            SessionID,
            BoardID,
            UserID,
            IP,
            Login,
            LastActive,
            Location,
            ForumID,
            TopicID,
            Browser,
            [Platform],
            Flags)
            values(
            @SessionID,
            @BoardID,
            @UserID,
            @IP,
            @UTCTIMESTAMP,
            @UTCTIMESTAMP,
            @Location,
            @ForumID,
            @TopicID,
            @Browser,
            @Platform,
            @ActiveFlags)

            -- update max user stats
            exec [{databaseOwner}].[{objectQualifier}active_updatemaxstats] @BoardID, @UTCTIMESTAMP
            -- parameter to update active users cache if this is a new user
            if @IsGuest=0
                  begin
                  set @ActiveUpdate = 1
            end

        end
        -- remove duplicate users
        if @IsGuest=0
        begin
            -- ensure that no duplicates
            delete from [{databaseOwner}].[{objectQualifier}Active] where UserID=@UserID and BoardID=@BoardID and SessionID<>@SessionID

        end

    end
    end
    -- return information
    select top 1
        ActiveUpdate        = ISNULL(@ActiveUpdate,0),
        PreviousVisit		= @PreviousVisit,
        x.*,
        IsModeratorAny      = ISNULL((select top 1 aa.ModeratorAccess from [{databaseOwner}].[{objectQualifier}ActiveAccess] aa where aa.UserID = @UserID and aa.ModeratorAccess = 1),0),
        IsCrawler           = @IsCrawler,
        IsMobileDevice      = @IsMobileDevice,
        CategoryID			= @CategoryID,
        CategoryName		= (select Name from [{databaseOwner}].[{objectQualifier}Category] where CategoryID = @CategoryID),
        ForumName			= (select Name from [{databaseOwner}].[{objectQualifier}Forum] where ForumID = @ForumID),
        TopicID				= @TopicID,
        TopicName			= (select Topic from [{databaseOwner}].[{objectQualifier}Topic] where TopicID = @TopicID),
        ForumTheme			= (select ThemeURL from [{databaseOwner}].[{objectQualifier}Forum] where ForumID = @ForumID),
		ParentForumID       = (select ParentID from [{databaseOwner}].[{objectQualifier}Forum] where ForumID = @ForumID)
    from
     [{databaseOwner}].[{objectQualifier}ActiveAccess] x
    where
        x.UserID = @UserID and x.ForumID=IsNull(@ForumID,0)
end
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}pmessage_delete](@UserPMessageID int, @FromOutbox bit = 0) as
BEGIN
        DECLARE @PMessageID int

    SET @PMessageID = (SELECT TOP 1 PMessageID FROM [{databaseOwner}].[{objectQualifier}UserPMessage] where UserPMessageID = @UserPMessageID);

    IF ( @FromOutbox = 1 AND EXISTS(SELECT (1) FROM [{databaseOwner}].[{objectQualifier}UserPMessage] WHERE UserPMessageID = @UserPMessageID AND IsInOutbox = 1 ) )
    BEGIN
        -- remove IsInOutbox bit which will remove it from the senders outbox
        UPDATE [{databaseOwner}].[{objectQualifier}UserPMessage] SET [Flags] = ([Flags] ^ 2) WHERE UserPMessageID = @UserPMessageID
    END

    IF ( @FromOutbox = 0 )
    BEGIN
            -- The pmessage is in archive but still is in sender outbox
    IF ( EXISTS(SELECT (1) FROM [{databaseOwner}].[{objectQualifier}UserPMessage] WHERE UserPMessageID = @UserPMessageID AND IsInOutbox = 1 AND IsArchived = 1 AND IsDeleted = 0) )
    BEGIN
    -- Remove archive flag and set IsDeleted flag
    UPDATE [{databaseOwner}].[{objectQualifier}UserPMessage] SET [Flags] = [Flags] ^ 4  WHERE UserPMessageID = @UserPMessageID AND IsArchived = 1
    END
        -- set is deleted...
        UPDATE [{databaseOwner}].[{objectQualifier}UserPMessage] SET [Flags] = ([Flags] ^ 8) WHERE UserPMessageID = @UserPMessageID
    END

    -- see if there are no longer references to this PM.
    IF ( EXISTS(SELECT (1) FROM [{databaseOwner}].[{objectQualifier}UserPMessage] WHERE UserPMessageID = @UserPMessageID AND IsInOutbox = 0 AND IsDeleted = 1 ) )
    BEGIN
        -- delete
        DELETE FROM [{databaseOwner}].[{objectQualifier}UserPMessage] WHERE [PMessageID] = @PMessageID
        DELETE FROM [{databaseOwner}].[{objectQualifier}PMessage] WHERE [PMessageID] = @PMessageID
    END

END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}pmessage_list](@FromUserID int=null,@ToUserID int=null,@UserPMessageID int=null) AS
BEGIN
        SELECT
    a.ReplyTo, a.PMessageID, b.UserPMessageID, a.FromUserID, 
    d.[Name] AS FromUser,
    d.UserStyle as FromStyle,
    d.Suspended as FromSuspended,
    b.[UserID] AS ToUserId, 
    c.[Name] AS ToUser, 
    c.UserStyle as ToStyle,
    c.Suspended as ToSuspended,
    a.Created, a.[Subject],
    a.Body, a.Flags, b.IsRead,b.IsReply, b.IsInOutbox, b.IsArchived, b.IsDeleted
FROM
    [{databaseOwner}].[{objectQualifier}PMessage] a
INNER JOIN
    [{databaseOwner}].[{objectQualifier}UserPMessage] b ON a.PMessageID = b.PMessageID
INNER JOIN
    [{databaseOwner}].[{objectQualifier}User] c ON b.UserID = c.UserID
INNER JOIN
    [{databaseOwner}].[{objectQualifier}User] d ON a.FromUserID = d.UserID
        WHERE	((@UserPMessageID IS NOT NULL AND b.UserPMessageID=@UserPMessageID) OR
                 (@ToUserID   IS NOT NULL AND b.[UserID]  = @ToUserID) OR (@FromUserID IS NOT NULL AND a.FromUserID = @FromUserID))
        ORDER BY Created DESC
END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}pmessage_markread](@UserPMessageID int=null)
AS
BEGIN
        UPDATE [{databaseOwner}].[{objectQualifier}UserPMessage] SET [Flags] = [Flags] | 1 WHERE UserPMessageID = @UserPMessageID AND IsRead = 0
END
GO

create procedure [{databaseOwner}].[{objectQualifier}pmessage_prune](@DaysRead int,@DaysUnread int,@UTCTIMESTAMP datetime) as
begin
    delete from [{databaseOwner}].[{objectQualifier}UserPMessage]
    where IsRead<>0
    and datediff(dd,(select Created from [{databaseOwner}].[{objectQualifier}PMessage] x where x.PMessageID=[{databaseOwner}].[{objectQualifier}UserPMessage].PMessageID),@UTCTIMESTAMP )>@DaysRead

    delete from [{databaseOwner}].[{objectQualifier}UserPMessage]
    where IsRead=0
    and datediff(dd,(select Created from [{databaseOwner}].[{objectQualifier}PMessage] x where x.PMessageID=[{databaseOwner}].[{objectQualifier}UserPMessage].PMessageID),@UTCTIMESTAMP )>@DaysUnread

    delete from [{databaseOwner}].[{objectQualifier}PMessage]
    where not exists(select 1 from [{databaseOwner}].[{objectQualifier}UserPMessage] x where x.PMessageID=[{databaseOwner}].[{objectQualifier}PMessage].PMessageID)
end
GO

create procedure [{databaseOwner}].[{objectQualifier}pmessage_save](
    @FromUserID	int,
    @ToUserID	int,
    @Subject	nvarchar(100),
    @Body		ntext,
    @Flags		int,
    @ReplyTo    int,
    @UTCTIMESTAMP datetime
) as
begin
    declare @PMessageID int
    declare @UserID int

    IF @ReplyTo<0
    begin
        insert into [{databaseOwner}].[{objectQualifier}PMessage](FromUserID,Created,Subject,Body,Flags)
        values(@FromUserID,@UTCTIMESTAMP ,@Subject,@Body,@Flags)
    end
    else
    begin
        insert into [{databaseOwner}].[{objectQualifier}PMessage](FromUserID,Created,Subject,Body,Flags,ReplyTo)
        values(@FromUserID,@UTCTIMESTAMP ,@Subject,@Body,@Flags,@ReplyTo)

        UPDATE [{databaseOwner}].[{objectQualifier}UserPMessage] SET [IsReply] = (1) WHERE PMessageID = @ReplyTo
    end

    set @PMessageID = SCOPE_IDENTITY()
    if (@ToUserID = 0)
    begin
        insert into [{databaseOwner}].[{objectQualifier}UserPMessage](UserID,PMessageID,Flags)
        select
                a.UserID,@PMessageID,2
        from
                [{databaseOwner}].[{objectQualifier}User] a
                join [{databaseOwner}].[{objectQualifier}UserGroup] b on b.UserID=a.UserID
                join [{databaseOwner}].[{objectQualifier}Group] c on c.GroupID=b.GroupID where
                (c.Flags & 2)=0 and
                c.BoardID=(select BoardID from [{databaseOwner}].[{objectQualifier}User] x where x.UserID=@FromUserID) and a.UserID<>@FromUserID
        group by
                a.UserID
    end
    else
    begin
        insert into [{databaseOwner}].[{objectQualifier}UserPMessage](UserID,PMessageID,Flags) values(@ToUserID,@PMessageID,2)
    end
end
GO


CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}pmessage_archive](@UserPMessageID int = NULL) AS
BEGIN
        -- set IsArchived bit
    UPDATE [{databaseOwner}].[{objectQualifier}UserPMessage] SET [Flags] = ([Flags] | 4) WHERE UserPMessageID = @UserPMessageID AND IsArchived = 0
END
GO

create procedure [{databaseOwner}].[{objectQualifier}post_alluser](@BoardID int,@UserID int,@PageUserID int,@topCount int = 0) as
begin
        IF (@topCount IS NULL) SET @topCount = 0;
        SET NOCOUNT ON
        SET ROWCOUNT @topCount

    select
        a.MessageID,
        a.Posted,
        [Subject] = c.Topic,
        a.[Message],
        a.IP,
        a.UserID,
        a.Flags,
        UserName = IsNull(a.UserName,b.Name),
        UserDisplayName = IsNull(a.UserDisplayName, b.DisplayName),
        b.[Signature],
        c.TopicID
    from
        [{databaseOwner}].[{objectQualifier}Message] a
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=a.UserID
        join [{databaseOwner}].[{objectQualifier}Topic] c on c.TopicID=a.TopicID
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
        join [{databaseOwner}].[{objectQualifier}Category] e on e.CategoryID=d.CategoryID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x   on x.ForumID=d.ForumID
    where
        a.UserID = @UserID and
        x.UserID = @PageUserID and
        CONVERT(int,x.ReadAccess) <> 0 and
        e.BoardID = @BoardID and
        (a.Flags & 24)=16 and
        c.IsDeleted=0
    order by
        a.Posted desc

    SET ROWCOUNT 0;
     SET NOCOUNT OFF
end
GO

create procedure [{databaseOwner}].[{objectQualifier}post_list](
                 @TopicID int,
                 @PageUserID int,
                 @AuthorUserID int,
                 @UpdateViewCount smallint=1,
                 @ShowDeleted bit = 1,
                 @StyledNicks bit = 0,
                 @ShowReputation bit = 0,
                 @SincePostedDate datetime,
                 @ToPostedDate datetime,
                 @SinceEditedDate datetime,
                 @ToEditedDate datetime,
                 @PageIndex int = 1,
                 @PageSize int = 0,
                 @SortPosted int = 2,
                 @SortEdited int = 0,
                 @SortPosition int = 0,
                 @ShowThanks bit = 0,
                 @MessagePosition int = 0,
                 @UTCTIMESTAMP datetime) as
begin
   declare @TotalPages int
   declare @TotalRows int
   declare @FirstSelectRowNumber int
   declare @LastSelectRowNumber int

   declare @firstselectrownum int

   declare @floor decimal
   declare @ceiling decimal

   declare @offset int

   declare @pageshift int;

    if @UpdateViewCount>0
        update [{databaseOwner}].[{objectQualifier}Topic] set [Views] = [Views] + 1 where TopicID = @TopicID
    -- find total returned count
        select
        @TotalRows = COUNT(m.MessageID)
    from
        [{databaseOwner}].[{objectQualifier}Message] m
    where
        m.TopicID = @TopicID
        AND m.IsApproved = 1
         -- is deleted
       AND (@ShowDeleted = 1 OR m.IsDeleted = 0 OR (@AuthorUserID > 0 AND m.UserID = @AuthorUserID))
        AND m.Posted BETWEEN
        @SincePostedDate AND @ToPostedDate
         /*
        AND
        m.Edited >= SinceEditedDate
        */

    select @TotalPages = CEILING(CONVERT(decimal,@TotalRows)/@PageSize);

	-- check if page index is bigger then Total pages
    if (@PageIndex > @TotalPages -1)
    begin
      set @PageIndex = @TotalPages -1
    end

 if (@MessagePosition > 0)
 begin

       -- round to ceiling - total number of pages
       SELECT @ceiling = CEILING(CONVERT(decimal,@TotalRows)/@PageSize)
       -- round to floor - a number of full pages
       SELECT @floor = FLOOR(CONVERT(decimal,@TotalRows)/@PageSize)

       SET @pageshift = @MessagePosition - (@TotalRows - @floor*@PageSize)
            if  @pageshift < 0
               begin
                  SET @pageshift = 0
                     end
   -- here pageshift converts to full pages
   if (@pageshift <= 0)
   begin
   set @pageshift = 0
   end
   else
   begin
   set @pageshift = CEILING(CONVERT(decimal,@pageshift)/@PageSize)
   end

   SET @PageIndex = @ceiling - @pageshift
   if @ceiling != @floor
   SET @PageIndex = @PageIndex - 1

   select @FirstSelectRowNumber = @PageIndex * @PageSize + 1;
   select @LastSelectRowNumber = @FirstSelectRowNumber + @PageSize - 1;
 end
 else
 begin
   select @PageIndex = @PageIndex+1;
   select @FirstSelectRowNumber = (@PageIndex - 1) * @PageSize + 1;
   select @LastSelectRowNumber = (@PageIndex - 1) * @PageSize + @PageSize;
 end;
    with MessageIds  as
     (
     select ROW_NUMBER() over (order by (case
        when @SortPosition = 1 then tt.Position end) ASC,
        (case
        when @SortPosted = 2 then tt.Posted end) DESC,
        (case
        when @SortPosted = 1 then tt.Posted end) ASC,
        (case
        when @SortEdited = 2 then tt.Edited end) DESC,
        (case
        when @SortEdited = 1 then tt.Edited end) ASC) as RowNum, tt.MessageID, tt.Position, tt.Posted, tt.Edited
     from  [{databaseOwner}].[{objectQualifier}Message] tt
     where    tt.TopicID = @TopicID
        AND tt.IsApproved = 1
       AND (@ShowDeleted = 1 OR tt.IsDeleted = 0 OR (@AuthorUserID > 0 AND tt.UserID = @AuthorUserID))
        AND (tt.Posted is null OR (tt.Posted is not null AND
        tt.Posted between @SincePostedDate and @ToPostedDate))
        /*
        AND (m.Edited is null OR (m.Edited is not null AND
        (m.Edited >= (case
        when @SortEdited = 1 then @firstselectedited end)
        OR m.Edited <= (case
        when @SortEdited = 2 then @firstselectedited end) OR
        m.Edited >= (case
        when @SortEdited = 0 then 0
        end))))
        */
      )
         select
        d.TopicID,
        d.Topic,
        d.Priority,
        d.Description,
        d.Status,
        d.Styles,
        d.PollID,
        d.UserID AS TopicOwnerID,
		d.AnswerMessageId,
        TopicFlags	= d.Flags,
        ForumFlags	= g.Flags,
		ForumName = g.Name,
        m.MessageID,
        m.Posted,
        [Message] = m.Message,
        m.UserID,
        m.Position,
        m.Indent,
        m.IP,
        m.Flags,
        m.EditReason,
        m.IsModeratorChanged,
        m.IsDeleted,
        m.DeleteReason,
        m.BlogPostID,
        m.ExternalMessageId,
        m.ReferenceMessageId,
        UserName = IsNull(m.UserName,b.Name),
        DisplayName =IsNull(m.UserDisplayName,b.DisplayName),
        b.BlockFlags,
        b.Suspended,
        b.Joined,
        b.Avatar,
        b.[Signature],
        Posts		= b.NumPosts,
        b.Points,
        ReputationVoteDate = (CASE WHEN @ShowReputation = 1 THEN CAST(ISNULL((select top 1 VoteDate from [{databaseOwner}].[{objectQualifier}ReputationVote] repVote where repVote.ReputationToUserID=b.UserID and repVote.ReputationFromUserID=@PageUserID), null) as datetime) ELSE @UTCTIMESTAMP END),
        IsGuest	= CONVERT(bit,IsNull(SIGN(b.Flags & 4),0)),
        d.[Views],
        d.ForumID,
        RankName = c.Name,
        c.Style as RankStyle,
        Style = case(@StyledNicks)
            when 1 then  b.UserStyle
            else ''	 end,
        Edited = IsNull(m.Edited,m.Posted),
        HasAvatarImage = ISNULL((select top 1 1 from [{databaseOwner}].[{objectQualifier}User] x where x.UserID=b.UserID and AvatarImage is not null),0),
        TotalRows = @TotalRows,
        PageIndex = @PageIndex
    from
        MessageIds ti
        inner join [{databaseOwner}].[{objectQualifier}Message] m
        ON m.MessageID = ti.MessageID
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=m.UserID
        join [{databaseOwner}].[{objectQualifier}Topic] d on d.TopicID=m.TopicID
        join [{databaseOwner}].[{objectQualifier}Forum] g on g.ForumID=d.ForumID
        join [{databaseOwner}].[{objectQualifier}Category] h on h.CategoryID=g.CategoryID
        join [{databaseOwner}].[{objectQualifier}Rank] c on c.RankID=b.RankID

        WHERE ti.RowNum between @FirstSelectRowNumber and @LastSelectRowNumber
        order by
            RowNum ASC
end
GO

create procedure [{databaseOwner}].[{objectQualifier}rank_save](
    @RankID		int,
    @BoardID	int,
    @Name		nvarchar(50),
    @IsStart	bit,
    @IsLadder	bit,
    @MinPosts	int,
    @PMLimit    int,
    @Style      nvarchar(255)=null,
    @SortOrder  smallint,
    @Description nvarchar(128)=null,
    @UsrSigChars int=null,
    @UsrSigBBCodes	nvarchar(255)=null,
    @UsrSigHTMLTags nvarchar(255)=null,
    @UsrAlbums int=null,
    @UsrAlbumImages int=null
) as
begin
        declare @Flags int

    if @IsLadder=0 set @MinPosts = null
    if @IsLadder=1 and @MinPosts is null set @MinPosts = 0

    set @Flags = 0
    if @IsStart<>0 set @Flags = @Flags | 1
    if @IsLadder<>0 set @Flags = @Flags | 2

    if @Style IS NOT NULL AND LEN(@Style) <=2 set @Style = NULL

    if @RankID>0 begin
        update [{databaseOwner}].[{objectQualifier}Rank] set
            Name = @Name,
            Flags = @Flags,
            MinPosts = @MinPosts,
            PMLimit = @PMLimit,
            Style = @Style,
            SortOrder = @SortOrder,
            [Description] = @Description,
            UsrSigChars = @UsrSigChars,
            UsrSigBBCodes = @UsrSigBBCodes,
            UsrSigHTMLTags = @UsrSigHTMLTags,
            UsrAlbums = @UsrAlbums,
            UsrAlbumImages = @UsrAlbumImages
        where RankID = @RankID
    end
    else begin
        insert into [{databaseOwner}].[{objectQualifier}Rank](BoardID,Name,Flags,MinPosts,PMLimit,Style,SortOrder,Description,UsrSigChars,UsrSigBBCodes,UsrSigHTMLTags,UsrAlbums,UsrAlbumImages)
        values(@BoardID,@Name,@Flags,@MinPosts,@PMLimit,@Style,@SortOrder,@Description,@UsrSigChars,@UsrSigBBCodes,@UsrSigHTMLTags,@UsrAlbums,@UsrAlbumImages);
        set @RankID = SCOPE_IDENTITY()
        -- select @RankID = RankID from [{databaseOwner}].[{objectQualifier}Rank] where RankID = @@Identity;
    end
        -- group styles override rank styles
 IF @Style IS NOT NULL AND len(@Style) > 2
      BEGIN
      EXEC [{databaseOwner}].[{objectQualifier}user_savestyle] null,@RankID
      END

end
GO

create procedure [{databaseOwner}].[{objectQualifier}registry_save](
    @Name nvarchar(50),
    @Value nvarchar(max) = NULL,
    @BoardID int = null
) AS
BEGIN
        if @BoardID is null
    begin
        if exists(select 1 from [{databaseOwner}].[{objectQualifier}Registry] where lower(Name)=lower(@Name))
            update [{databaseOwner}].[{objectQualifier}Registry] set Value = @Value where lower(Name)=lower(@Name) and BoardID is null
        else
        begin
            insert into [{databaseOwner}].[{objectQualifier}Registry](Name,Value) values(lower(@Name),@Value)
        end
    end else
    begin
        if exists(select 1 from [{databaseOwner}].[{objectQualifier}Registry] where lower(Name)=lower(@Name) and BoardID=@BoardID)
            update [{databaseOwner}].[{objectQualifier}Registry] set Value = @Value where lower(Name)=lower(@Name) and BoardID=@BoardID
        else
        begin
            insert into [{databaseOwner}].[{objectQualifier}Registry](Name,Value,BoardID) values(lower(@Name),@Value,@BoardID)
        end
    end
END
GO

create procedure [{databaseOwner}].[{objectQualifier}system_initialize](
    @Name		nvarchar(50),
    @TimeZone	nvarchar(max),
    @Culture	varchar(10),
    @LanguageFile nvarchar(50),
    @ForumEmail	nvarchar(50),
	@ForumLogo	nvarchar(255),
	@ForumBaseUrlMask	nvarchar(255),
    @SmtpServer	nvarchar(50),
    @User		nvarchar(255),
    @UserEmail	nvarchar(255),
    @UserKey	nvarchar(64),
    @RolePrefix nvarchar(255),
    @UTCTIMESTAMP datetime

) as
begin
        DECLARE @tmpValue AS nvarchar(100)

    -- initalize required 'registry' settings
    EXEC [{databaseOwner}].[{objectQualifier}registry_save] 'version','1'
    EXEC [{databaseOwner}].[{objectQualifier}registry_save] 'versionname','1.0.0'
    EXEC [{databaseOwner}].[{objectQualifier}registry_save] 'timezone', @TimeZone
    EXEC [{databaseOwner}].[{objectQualifier}registry_save] 'culture', @Culture
    EXEC [{databaseOwner}].[{objectQualifier}registry_save] 'language', @LanguageFile
    EXEC [{databaseOwner}].[{objectQualifier}registry_save] 'smtpserver', @SmtpServer
    EXEC [{databaseOwner}].[{objectQualifier}registry_save] 'forumemail', @ForumEmail
    EXEC [{databaseOwner}].[{objectQualifier}registry_save] 'forumlogo', @ForumLogo
	EXEC [{databaseOwner}].[{objectQualifier}registry_save] 'baseurlmask', @ForumBaseUrlMask

    -- initalize new board
    EXEC [{databaseOwner}].[{objectQualifier}board_create] @Name, @Culture, @LanguageFile, @User,@UserEmail,@UserKey,1,@RolePrefix,@UTCTIMESTAMP
end
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}system_updateversion]
(
    @Version		int,
    @VersionName	nvarchar(50)
)
AS
BEGIN
        DECLARE @tmpValue AS nvarchar(100)
    SET @tmpValue = CAST(@Version AS nvarchar(100))
    EXEC [{databaseOwner}].[{objectQualifier}registry_save] 'version', @tmpValue
    EXEC [{databaseOwner}].[{objectQualifier}registry_save] 'versionname',@VersionName

END
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}topic_unread]
(   @BoardID int,
    @CategoryID int=null,
    @PageUserID int,
    @SinceDate datetime=null,
    @ToDate datetime,
    @PageIndex int = 1,
    @PageSize int = 0,
    @StyledNicks bit = 0,
    @FindLastRead bit = 0
)
AS
begin
   declare @post_totalrowsnumber int
   declare @firstselectrownum int
   declare @firstselectposted datetime
  -- declare @ceiling decimal
  -- declare @offset int

    set nocount on

    -- find total returned count
        select
        @post_totalrowsnumber = count(1)
        from
        [{databaseOwner}].[{objectQualifier}Topic] c
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=c.UserID
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x   on x.ForumID=d.ForumID
        join [{databaseOwner}].[{objectQualifier}Category] cat on cat.CategoryID=d.CategoryID
    where
        (c.LastPosted between @SinceDate and @ToDate) and
        x.UserID = @PageUserID and
        CONVERT(int,x.ReadAccess) <> 0 and
        cat.BoardID = @BoardID and
        (@CategoryID is null or cat.CategoryID=@CategoryID) and
        c.IsDeleted = 0
        and	c.TopicMovedID is null

      select @PageIndex = @PageIndex+1;
      select @firstselectrownum = (@PageIndex - 1) * @PageSize + 1
        -- find first selectedrowid
   if (@firstselectrownum > 0)
   set rowcount @firstselectrownum
   else
   -- should not be 0
   set rowcount 1

   select
        @firstselectposted = c.LastPosted
    from
            [{databaseOwner}].[{objectQualifier}Topic] c
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=c.UserID
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x   on x.ForumID=d.ForumID
        join [{databaseOwner}].[{objectQualifier}Category] cat on cat.CategoryID=d.CategoryID
    where
        (c.LastPosted between @SinceDate and @ToDate) and
        x.UserID = @PageUserID and
        CONVERT(int,x.ReadAccess) <> 0 and
        cat.BoardID = @BoardID and
        (@CategoryID is null or cat.CategoryID=@CategoryID) and
        c.IsDeleted = 0
        and	c.TopicMovedID is null
    order by
        c.LastPosted desc,
        cat.SortOrder asc,
        d.SortOrder asc,
        d.Name asc,
        c.Priority desc

    set rowcount @PageSize
            select
        c.ForumID,
        c.TopicID,
        c.TopicMovedID,
        c.Posted,
        LinkTopicID = IsNull(c.TopicMovedID,c.TopicID),
        [Subject] = c.Topic,
        [Description] = c.Description,
        [Status] = c.Status,
        [Styles] = c.Styles,
        c.UserID,
        Starter = IsNull(c.UserName,b.Name),
        StarterDisplay = IsNull(c.UserDisplayName,b.DisplayName),
        NumPostsDeleted = (SELECT COUNT(1) FROM [{databaseOwner}].[{objectQualifier}Message] mes WHERE mes.TopicID = c.TopicID AND mes.IsDeleted = 1 AND mes.IsApproved = 1 AND ((@PageUserID IS NOT NULL AND mes.UserID = @PageUserID) OR (@PageUserID IS NULL)) ),
        Replies = (select count(1) from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=c.TopicID and x.IsDeleted=0) - 1,
        [Views] = c.[Views],
        LastPosted = c.LastPosted,
        LastUserID = c.LastUserID,
        LastUserName = lastUser.Name,
        LastUserDisplayName = lastUser.DisplayName,
        LastMessageID = c.LastMessageID,
        LastMessageFlags = c.LastMessageFlags,
        LastTopicID = c.TopicID,
        TopicFlags = c.Flags,
        FavoriteCount = (SELECT COUNT(ID) as [FavoriteCount] FROM [{databaseOwner}].[{objectQualifier}FavoriteTopic] WHERE TopicID = IsNull(c.TopicMovedID,c.TopicID)),
        c.Priority,
        c.PollID,
        ForumName = d.Name,
        c.TopicMovedID,
        ForumFlags = d.Flags,
        FirstMessage = (SELECT TOP 1 CAST([Message] as nvarchar(1000)) FROM [{databaseOwner}].[{objectQualifier}Message] mes2 where mes2.TopicID = IsNull(c.TopicMovedID,c.TopicID) AND mes2.Position = 0),
        StarterSuspended = b.Suspended,
        LastUserSuspended = lastUser.Suspended,
        StarterStyle = case(@StyledNicks)
            when 1 then  b.UserStyle
            else ''	 end,
        LastUserStyle= case(@StyledNicks)
            when 1 then  (select top 1 usr.[UserStyle] from [{databaseOwner}].[{objectQualifier}User] usr  where usr.UserID = c.LastUserID)
            else ''	 end,
        LastForumAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}ForumReadTracking] x WHERE x.ForumID=d.ForumID AND x.UserID = @PageUserID)
             else ''	 end,
        LastTopicAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}TopicReadTracking] y WHERE y.TopicID=c.TopicID AND y.UserID = @PageUserID)
             else ''	 end,
        TotalRows = @post_totalrowsnumber,
        PageIndex = @PageIndex
    from
        [{databaseOwner}].[{objectQualifier}Topic] c
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=c.UserID
        join [{databaseOwner}].[{objectQualifier}User] lastUser on lastUser.UserID = c.LastUserID
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x   on x.ForumID=d.ForumID
        join [{databaseOwner}].[{objectQualifier}Category] cat on cat.CategoryID=d.CategoryID
    where
        c.LastPosted <= @firstselectposted and
        x.UserID = @PageUserID and
        CONVERT(int,x.ReadAccess) <> 0 and
        cat.BoardID = @BoardID and
        (@CategoryID is null or cat.CategoryID=@CategoryID) and
        c.IsDeleted = 0
        and	c.TopicMovedID is null
    order by
        c.LastPosted desc,
        cat.SortOrder asc,
        d.SortOrder asc,
        d.Name asc,
        c.Priority desc

        SET ROWCOUNT 0
end
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}topic_active]
(   @BoardID int,
    @CategoryID int=null,
    @PageUserID int,
    @SinceDate datetime,
    @ToDate datetime,
    @PageIndex int = 1,
    @PageSize int = 0,
    @StyledNicks bit = 0,
    @FindLastRead bit = 0
)
AS
begin
   declare @TotalRows int
   declare @FirstSelectRowNumber int
   declare @LastSelectRowNumber int

   -- find total returned count
   select  @TotalRows = count(1)
        from
        [{databaseOwner}].[{objectQualifier}Topic] c
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=c.UserID
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x   on x.ForumID=d.ForumID
        join [{databaseOwner}].[{objectQualifier}Category] cat on cat.CategoryID=d.CategoryID
    where
        (c.LastPosted between @SinceDate and @ToDate) and
        x.UserID = @PageUserID and
        CONVERT(int,x.ReadAccess) <> 0 and
        cat.BoardID = @BoardID and
        (@CategoryID is null or cat.CategoryID=@CategoryID) and
        c.IsDeleted = 0
        and	c.TopicMovedID is null

    select @PageIndex = @PageIndex+1;
    select @FirstSelectRowNumber = (@PageIndex - 1) * @PageSize + 1;
    select @LastSelectRowNumber = (@PageIndex - 1) * @PageSize + @PageSize;

    with TopicIds  as
     (
     select ROW_NUMBER() over (order by cat.SortOrder asc, d.SortOrder asc, c.LastPosted desc) as RowNum, c.TopicID
     from  [{databaseOwner}].[{objectQualifier}Topic] c
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x   on x.ForumID=d.ForumID
        join [{databaseOwner}].[{objectQualifier}Category] cat on cat.CategoryID=d.CategoryID
     where
        (c.LastPosted between @SinceDate and @ToDate) and
        x.UserID = @PageUserID and
        CONVERT(int,x.ReadAccess) <> 0 and
        cat.BoardID = @BoardID and
        (@CategoryID is null or cat.CategoryID=@CategoryID) and
        c.IsDeleted = 0
        and	c.TopicMovedID is null
      )
      select
        c.ForumID,
        c.TopicID,
        c.TopicMovedID,
        c.Posted,
        LinkTopicID = IsNull(c.TopicMovedID,c.TopicID),
        [Subject] = c.Topic,
        [Description] = c.Description,
        [Status] = c.Status,
        [Styles] = c.Styles,
        c.UserID,
        Starter = IsNull(c.UserName,b.Name),
        StarterDisplay = IsNull(c.UserDisplayName, b.DisplayName),
        NumPostsDeleted = (SELECT COUNT(1) FROM [{databaseOwner}].[{objectQualifier}Message] mes WHERE mes.TopicID = c.TopicID AND mes.IsDeleted = 1 AND mes.IsApproved = 1 AND ((@PageUserID IS NOT NULL AND mes.UserID = @PageUserID) OR (@PageUserID IS NULL)) ),
        Replies = (select count(1) from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=c.TopicID and x.IsDeleted=0) - 1,
        [Views] = c.[Views],
        LastPosted = c.LastPosted,
        LastUserID = c.LastUserID,
        LastUserName = lastUser.Name,
        LastUserDisplayName = lastUser.DisplayName,
        LastMessageID = c.LastMessageID,
        LastMessageFlags = c.LastMessageFlags,
        LastTopicID = c.TopicID,
        TopicFlags = c.Flags,
        FavoriteCount = (SELECT COUNT(ID) as [FavoriteCount] FROM [{databaseOwner}].[{objectQualifier}FavoriteTopic] WHERE TopicID = IsNull(c.TopicMovedID,c.TopicID)),
        c.Priority,
        c.PollID,
        ForumName = d.Name,
        c.TopicMovedID,
        ForumFlags = d.Flags,
        FirstMessage = (SELECT TOP 1 CAST([Message] as nvarchar(1000)) FROM [{databaseOwner}].[{objectQualifier}Message] mes2 where mes2.TopicID = IsNull(c.TopicMovedID,c.TopicID) AND mes2.Position = 0),
        StarterSuspended = b.Suspended,
        LastUserSuspended = lastUser.Suspended,
        StarterStyle = case(@StyledNicks)
            when 1 then  b.UserStyle
            else ''	 end,
        LastUserStyle= case(@StyledNicks)
            when 1 then  (select top 1 usr.[UserStyle] from [{databaseOwner}].[{objectQualifier}User] usr  where usr.UserID = c.LastUserID)
            else ''	 end,
        LastForumAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}ForumReadTracking] x WHERE x.ForumID=d.ForumID AND x.UserID = @PageUserID)
             else ''	 end,
        LastTopicAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}TopicReadTracking] y WHERE y.TopicID=c.TopicID AND y.UserID = @PageUserID)
             else ''	 end,
        TotalRows = @TotalRows,
        PageIndex = @PageIndex
    from
        TopicIds ti
        inner join [{databaseOwner}].[{objectQualifier}Topic] c on c.TopicID = ti.TopicID
        join [{databaseOwner}].[{objectQualifier}User] lastUser on lastUser.UserID = c.LastUserID
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=c.UserID
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
    where ti.RowNum between @FirstSelectRowNumber and @LastSelectRowNumber
        order by
            RowNum ASC

end
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}topic_delete] (@TopicID int,@UpdateLastPost bit=1,@EraseTopic bit=0)
AS
BEGIN
        SET NOCOUNT ON
    DECLARE @ForumID int

    SELECT @ForumID=ForumID FROM  [{databaseOwner}].[{objectQualifier}Topic] WHERE TopicID=@TopicID

    UPDATE [{databaseOwner}].[{objectQualifier}Topic] SET LastMessageID = null WHERE TopicID = @TopicID

    UPDATE [{databaseOwner}].[{objectQualifier}Forum] SET
        LastTopicID = null,
        LastMessageID = null,
        LastUserID = null,
        LastUserName = null,
        LastUserDisplayName = null,
        LastPosted = null
    WHERE LastMessageID IN (SELECT MessageID FROM  [{databaseOwner}].[{objectQualifier}Message] WHERE TopicID = @TopicID)

    UPDATE  [{databaseOwner}].[{objectQualifier}Active] SET TopicID = null WHERE TopicID = @TopicID

    --delete messages and topics
    DELETE FROM  [{databaseOwner}].[{objectQualifier}nntptopic] WHERE TopicID = @TopicID

    IF @EraseTopic = 0
    BEGIN
        UPDATE  [{databaseOwner}].[{objectQualifier}topic] set Flags = Flags | 8 where TopicMovedID = @TopicID
        UPDATE  [{databaseOwner}].[{objectQualifier}topic] set Flags = Flags | 8 where TopicID = @TopicID
        UPDATE  [{databaseOwner}].[{objectQualifier}Message] set Flags = Flags | 8 where TopicID = @TopicID
    END
    ELSE
    BEGIN
        DELETE FROM  [{databaseOwner}].[{objectQualifier}topic] WHERE TopicMovedID = @TopicID

        DELETE  [{databaseOwner}].[{objectQualifier}Attachment] WHERE MessageID IN (SELECT MessageID FROM  [{databaseOwner}].[{objectQualifier}message] WHERE TopicID = @TopicID)
        DELETE  [{databaseOwner}].[{objectQualifier}MessageHistory] WHERE MessageID IN (SELECT MessageID FROM  [{databaseOwner}].[{objectQualifier}message] WHERE TopicID = @TopicID)

		update [{databaseOwner}].[{objectQualifier}Message] SET ReplyTo = null WHERE TopicID = @TopicID

		-- update user post count
		if not exists(select top 1 1 from [{databaseOwner}].[{objectQualifier}Forum] where ForumID=@ForumID and (Flags & 4)=0)
          -- delete messages
		  DELETE  [{databaseOwner}].[{objectQualifier}Message] WHERE TopicID = @TopicID
        else
		   begin
		   declare @tmpUserID int;
		   declare message_cursor cursor for
		   select UserID from [{databaseOwner}].[{objectQualifier}Message]
		   where TopicID=@TopicID

           -- delete messages
		   open message_cursor

		   fetch next from message_cursor
		   into @tmpUserID

		   -- Check @@FETCH_STATUS to see if there are any more rows to fetch.
		   while @@FETCH_STATUS = 0
    		   begin
		   UPDATE [{databaseOwner}].[{objectQualifier}User] SET NumPosts = (SELECT count(MessageID) FROM [{databaseOwner}].[{objectQualifier}Message] WHERE UserID = @tmpUserID AND IsDeleted = 0 AND IsApproved = 1) WHERE UserID = @tmpUserID

		   DELETE  [{databaseOwner}].[{objectQualifier}Message] WHERE TopicID = @TopicID and UserID = @tmpUserID

		   -- This is executed as long as the previous fetch succeeds.
		   fetch next from message_cursor
		   into @tmpUserID
		   end

		   close message_cursor
		   deallocate message_cursor

		end

		delete [{databaseOwner}].[{objectQualifier}TopicTag] where TopicID = @TopicID
		delete [{databaseOwner}].[{objectQualifier}Activity] where TopicID = @TopicID
        DELETE  [{databaseOwner}].[{objectQualifier}WatchTopic] WHERE TopicID = @TopicID
        DELETE  [{databaseOwner}].[{objectQualifier}TopicReadTracking] WHERE TopicID = @TopicID
        DELETE  [{databaseOwner}].[{objectQualifier}FavoriteTopic]  WHERE TopicID = @TopicID
        DELETE  [{databaseOwner}].[{objectQualifier}Topic] WHERE TopicMovedID = @TopicID
        DELETE  [{databaseOwner}].[{objectQualifier}Topic] WHERE TopicID = @TopicID
        DELETE  [{databaseOwner}].[{objectQualifier}MessageReportedAudit] WHERE MessageID IN (SELECT MessageID FROM  [{databaseOwner}].[{objectQualifier}message] WHERE TopicID = @TopicID)
        DELETE  [{databaseOwner}].[{objectQualifier}MessageReported] WHERE MessageID IN (SELECT MessageID FROM  [{databaseOwner}].[{objectQualifier}message] WHERE TopicID = @TopicID)

		END

    --commit
    IF @UpdateLastPost<>0
        EXEC  [{databaseOwner}].[{objectQualifier}forum_updatelastpost] @ForumID

    IF @ForumID is not null
        EXEC  [{databaseOwner}].[{objectQualifier}forum_updatestats] @ForumID
END
GO

create procedure [{databaseOwner}].[{objectQualifier}topic_findnext](@TopicID int) as
begin
    declare @LastPosted datetime
    declare @ForumID int
    select @LastPosted = LastPosted, @ForumID = ForumID from [{databaseOwner}].[{objectQualifier}Topic] where TopicID = @TopicID AND TopicMovedID IS NULL
    select top 1 TopicID from [{databaseOwner}].[{objectQualifier}Topic] where LastPosted>@LastPosted and ForumID = @ForumID AND IsDeleted=0 AND TopicMovedID IS NULL order by LastPosted asc
end
GO

create procedure [{databaseOwner}].[{objectQualifier}topic_findprev](@TopicID int) AS
BEGIN
    DECLARE @LastPosted datetime
    DECLARE @ForumID int
    SELECT @LastPosted = LastPosted, @ForumID = ForumID FROM [{databaseOwner}].[{objectQualifier}Topic] WHERE TopicID = @TopicID AND TopicMovedID IS NULL
    SELECT TOP 1 TopicID from [{databaseOwner}].[{objectQualifier}Topic] where LastPosted<@LastPosted AND ForumID = @ForumID AND IsDeleted=0 AND TopicMovedID IS NULL ORDER BY LastPosted DESC
END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}topic_announcements]
(
    @BoardID int,
    @NumPosts int,
    @PageUserID int
)
AS
BEGIN
    SELECT DISTINCT TOP (@NumPosts)
	t.Topic,
	t.LastPosted,
	t.Posted,
	t.UserID,
	t.LastUserID,
	t.TopicID,
	t.TopicMovedID,
	Message = (select  CONVERT(VARCHAR(MAX), m.Message) from [{databaseOwner}].[{objectQualifier}Message] m where t.LastMessageID = m.MessageID),
	t.LastMessageID,
	t.LastMessageFlags
	FROM
    [{databaseOwner}].[{objectQualifier}Topic] t
    INNER JOIN [{databaseOwner}].[{objectQualifier}Forum] f ON t.ForumID = f.ForumID
    INNER JOIN [{databaseOwner}].[{objectQualifier}Category] c
    ON c.CategoryID = f.CategoryID
    join [{databaseOwner}].[{objectQualifier}ActiveAccess] v   on v.ForumID=f.ForumID
    WHERE c.BoardID = @BoardID AND v.UserID=@PageUserID AND (CONVERT(int,v.ReadAccess) <> 0 or (f.Flags & 2) = 0) AND t.IsDeleted=0 AND t.TopicMovedID IS NULL AND (t.Priority = 2) ORDER BY t.LastPosted DESC;
END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}rss_topic_latest]
(
    @BoardID int,
    @NumPosts int,
    @PageUserID int,
    @StyledNicks bit = 0,
    @ShowNoCountPosts  bit = 0
)
AS
BEGIN
    SELECT TOP(@NumPosts)
        LastMessage = m.[Message],
        t.LastPosted,
        t.ForumID,
        f.Name as Forum,
        t.Topic,
        t.TopicID,
        t.TopicMovedID,
        t.UserID,
        t.UserName,
        t.UserDisplayName,
        StarterIsGuest = (select x.IsGuest from [{databaseOwner}].[{objectQualifier}User] x where x.UserID=t.UserID),
        t.LastMessageID,
        t.LastMessageFlags,
        t.LastUserID,
        LastUserName = lastUser.Name,
        LastUserDisplayName = lastUser.DisplayName,
        LastUserIsGuest = (select x.IsGuest from [{databaseOwner}].[{objectQualifier}User] x where x.UserID=t.LastUserID),
        t.Posted
    FROM
        [{databaseOwner}].[{objectQualifier}Message] m
    INNER JOIN
        [{databaseOwner}].[{objectQualifier}Topic] t  ON t.LastMessageID = m.MessageID
    inner join 
        [{databaseOwner}].[{objectQualifier}User] lastUser on lastUser.UserID = t.LastUserID
    INNER JOIN
        [{databaseOwner}].[{objectQualifier}Forum] f ON t.ForumID = f.ForumID
    INNER JOIN
        [{databaseOwner}].[{objectQualifier}Category] c ON c.CategoryID = f.CategoryID
    JOIN
        [{databaseOwner}].[{objectQualifier}ActiveAccess] v   ON v.ForumID=f.ForumID
    WHERE
        c.BoardID = @BoardID
        AND t.TopicMovedID is NULL
        AND v.UserID=@PageUserID
        AND (CONVERT(int,v.ReadAccess) <> 0)
        AND t.IsDeleted != 1
        AND t.LastPosted IS NOT NULL
        AND
        f.Flags & 4 <> (CASE WHEN @ShowNoCountPosts > 0 THEN -1 ELSE 4 END)
    ORDER BY
        t.LastPosted DESC;
END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}topic_latest]
(
    @BoardID int,
    @NumPosts int,
    @PageUserID int,
    @StyledNicks bit = 0,
    @ShowNoCountPosts  bit = 0,
    @FindLastRead bit = 0
)
AS
BEGIN

    SELECT TOP(@NumPosts)
        t.LastPosted,
        t.ForumID,
        f.Name as Forum,
        t.Topic,
        t.Status,
        t.Styles,
        t.TopicID,
        t.TopicMovedID,
        t.UserID,
        UserName = IsNull(t.UserName,(select x.[Name] from [{databaseOwner}].[{objectQualifier}User] x where x.UserID = t.UserID)),
        UserDisplayName = IsNull(t.UserDisplayName,(select x.[DisplayName] from [{databaseOwner}].[{objectQualifier}User] x where x.UserID = t.UserID)),
        t.LastMessageID,
        t.LastMessageFlags,
        t.LastUserID,
        t.NumPosts,
		t.Views,
        t.Posted,
		LastMessage = (select m.Message from [{databaseOwner}].[{objectQualifier}Message] m where m.MessageID = t.LastMessageID),
        LastUserName = lastUser.Name,
        LastUserDisplayName = lastUser.DisplayName,
        LastUserStyle = case(@StyledNicks)
            when 1 then  (select top 1 usr.[UserStyle] from [{databaseOwner}].[{objectQualifier}User] usr  where usr.UserID = t.LastUserID)
            else ''	 end,
        LastForumAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}ForumReadTracking] x WHERE x.ForumID=f.ForumID AND x.UserID = @PageUserID)
             else ''	 end,
        LastTopicAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}TopicReadTracking] y WHERE y.TopicID=t.TopicID AND y.UserID = @PageUserID)
             else ''	 end

    FROM
        [{databaseOwner}].[{objectQualifier}Topic] t
    INNER JOIN
        [{databaseOwner}].[{objectQualifier}Forum] f ON t.ForumID = f.ForumID
    inner join 
        [{databaseOwner}].[{objectQualifier}User] lastUser on lastUser.UserID = t.LastUserID
    INNER JOIN
        [{databaseOwner}].[{objectQualifier}Category] c ON c.CategoryID = f.CategoryID
    JOIN
        [{databaseOwner}].[{objectQualifier}ActiveAccess] v   ON v.ForumID=f.ForumID
    WHERE
        c.BoardID = @BoardID
        AND t.TopicMovedID is NULL
        AND v.UserID=@PageUserID
        AND (CONVERT(int,v.ReadAccess) <> 0)
        AND t.IsDeleted != 1
        AND t.LastPosted IS NOT NULL
        AND
        f.Flags & 4 <> (CASE WHEN @ShowNoCountPosts > 0 THEN -1 ELSE 4 END)
    ORDER BY
        t.LastPosted DESC;
END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}rsstopic_list]
(
    @ForumID int,
    @TopicLimit int
)
as
begin

    select top(@TopicLimit)
	Topic = a.Topic,
	TopicID = a.TopicID,
	Name = b.Name,
	LastPosted = IsNull(a.LastPosted,a.Posted),
	LastUserID = IsNull(a.LastUserID, a.UserID),
	LastMessageID= IsNull(a.LastMessageID,
	(select top 1 m.MessageID
	from [{databaseOwner}].[{objectQualifier}Message] m where m.TopicID = a.TopicID order by m.Posted desc)),
	LastMessageFlags = IsNull(a.LastMessageFlags,22) ,
	LastMessage = (SELECT TOP 1 CAST([Message] as nvarchar(1000)) FROM [{databaseOwner}].[{objectQualifier}Message] mes2 where mes2.TopicID = IsNull(a.TopicMovedID,a.TopicID) AND mes2.IsApproved = 1 AND mes2.IsDeleted = 0 ORDER BY mes2.Posted DESC)

from [{databaseOwner}].[{objectQualifier}Topic] a,
     [{databaseOwner}].[{objectQualifier}Forum] b

where a.ForumID = @ForumID and
      b.ForumID = a.ForumID and
	  a.TopicMovedID is null and
	  a.IsDeleted = 0 and
	  a.NumPosts > 0

order by LastPosted desc
end
go

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}topic_latest_in_category]
(
    @BoardID int,
    @CategoryID int,
	@NumPosts int,
    @PageUserID int,
    @StyledNicks bit = 0,
    @ShowNoCountPosts  bit = 0,
    @FindLastRead bit = 0
)
AS
BEGIN

    SELECT TOP(@NumPosts)
        t.LastPosted,
        t.ForumID,
        f.Name as Forum,
        t.Topic,
        t.Status,
        t.Styles,
        t.TopicID,
        t.TopicMovedID,
        t.UserID,
        UserName = IsNull(t.UserName,(select x.[Name] from [{databaseOwner}].[{objectQualifier}User] x where x.UserID = t.UserID)),
        UserDisplayName = IsNull(t.UserDisplayName,(select x.[DisplayName] from [{databaseOwner}].[{objectQualifier}User] x where x.UserID = t.UserID)),
        t.LastMessageID,
        t.LastMessageFlags,
        t.LastUserID,
        t.NumPosts,
		t.Views,
        t.Posted,
		LastMessage = (select m.Message from [{databaseOwner}].[{objectQualifier}Message] m where m.MessageID = t.LastMessageID),
        LastUserName = lastUser.Name,
        LastUserDisplayName = lastUser.DisplayName,
        LastUserStyle = case(@StyledNicks)
            when 1 then  (select top 1 usr.[UserStyle] from [{databaseOwner}].[{objectQualifier}User] usr  where usr.UserID = t.LastUserID)
            else ''	 end,
        LastForumAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}ForumReadTracking] x WHERE x.ForumID=f.ForumID AND x.UserID = @PageUserID)
             else ''	 end,
        LastTopicAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}TopicReadTracking] y WHERE y.TopicID=t.TopicID AND y.UserID = @PageUserID)
             else ''	 end

    FROM
        [{databaseOwner}].[{objectQualifier}Topic] t
    INNER JOIN
        [{databaseOwner}].[{objectQualifier}Forum] f ON t.ForumID = f.ForumID
    inner join 
        [{databaseOwner}].[{objectQualifier}User] lastUser on lastUser.UserID = t.LastUserID
    INNER JOIN
        [{databaseOwner}].[{objectQualifier}Category] c ON c.CategoryID = f.CategoryID
    JOIN
        [{databaseOwner}].[{objectQualifier}ActiveAccess] v   ON v.ForumID=f.ForumID
    WHERE
	    c.BoardID = @BoardID
        AND c.CategoryID = @CategoryID
        AND t.TopicMovedID is NULL
        AND v.UserID=@PageUserID
        AND (CONVERT(int,v.ReadAccess) <> 0)
        AND t.IsDeleted != 1
        AND t.LastPosted IS NOT NULL
        AND
        f.Flags & 4 <> (CASE WHEN @ShowNoCountPosts > 0 THEN -1 ELSE 4 END)
    ORDER BY
        t.LastPosted DESC;
END
GO


CREATE procedure [{databaseOwner}].[{objectQualifier}announcements_list]
(
    @ForumID int,
    @UserID int = null,
    @Date datetime=null,
    @ToDate datetime=null,
    @PageIndex int = 1,
    @PageSize int = 0,
    @StyledNicks bit = 0,
    @ShowMoved  bit = 0,
    @FindLastRead bit = 0
)
AS
begin
   declare @TotalRows int
   declare @FirstSelectRowNumber int
   declare @LastSelectRowNumber int

   -- find total returned count
   select  @TotalRows = COUNT(c.TopicID)
   FROM [{databaseOwner}].[{objectQualifier}Topic] c
   WHERE c.ForumID = @ForumID
   AND	c.[Priority] = 2
   AND	c.IsDeleted = 0
    AND	(c.TopicMovedID IS NOT NULL OR c.NumPosts > 0)
    AND
    (@ShowMoved = 1 or (@ShowMoved <> 1 AND  c.TopicMovedID IS NULL))

    select @PageIndex = @PageIndex+1;
    select @FirstSelectRowNumber = (@PageIndex - 1) * @PageSize + 1;
    select @LastSelectRowNumber = (@PageIndex - 1) * @PageSize + @PageSize;

    with TopicIds  as
     (
     select ROW_NUMBER() over (order by tt.[Priority] desc,tt.LastPosted desc) as RowNum, tt.TopicID
     from  [{databaseOwner}].[{objectQualifier}Topic] tt
     where tt.ForumID = @ForumID and tt.[Priority] = 2
      AND	tt.IsDeleted = 0
      AND	((tt.TopicMovedID IS NOT NULL) OR (tt.NumPosts > 0))
      AND
      (@ShowMoved = 1 or (@ShowMoved <> 1 AND  TopicMovedID IS NULL))
      )
      select
            c.ForumID,
            c.TopicID,
            c.Posted,
            LinkTopicID = IsNull(c.TopicMovedID,c.TopicID),
            c.TopicMovedID,
            FavoriteCount = (SELECT COUNT(1) as [FavoriteCount] FROM [{databaseOwner}].[{objectQualifier}FavoriteTopic] WHERE TopicID = IsNull(c.TopicMovedID,c.TopicID)),
            [Subject] = c.Topic,
            c.[Description],
            c.[Status],
            c.[Styles],
            c.UserID,
            Starter = IsNull(c.UserName,b.Name),
            StarterDisplay = IsNull(c.UserDisplayName,b.DisplayName),
            Replies = c.NumPosts - 1,
            NumPostsDeleted = (SELECT COUNT(1) FROM [{databaseOwner}].[{objectQualifier}Message] mes WHERE mes.TopicID = c.TopicID AND mes.IsDeleted = 1 AND mes.IsApproved = 1 AND ((@UserID IS NOT NULL AND mes.UserID = @UserID) OR (@UserID IS NULL)) ),
            [Views] = c.[Views],
            LastPosted = c.LastPosted,
            LastUserID = c.LastUserID,
            LastUserName = lastUser.Name,
            LastUserDisplayName = lastUser.DisplayName,
            LastMessageID = c.LastMessageID,
            LastTopicID = c.TopicID,
            LinkDate = c.LinkDate,
            TopicFlags = c.Flags,
            c.Priority,
            c.PollID,
            ForumFlags = d.Flags,
            FirstMessage = (SELECT TOP 1 CAST([Message] as nvarchar(1000)) FROM [{databaseOwner}].[{objectQualifier}Message] mes2 where mes2.TopicID = IsNull(c.TopicMovedID,c.TopicID) AND mes2.Position = 0),
            StarterStyle = case(@StyledNicks)
            when 1 then  b.UserStyle
            else ''	 end,
            StarterSuspended = b.Suspended,
            LastUserSuspended = lastUser.Suspended,
            LastUserStyle= case(@StyledNicks)
            when 1 then  (select top 1 usr.[UserStyle] from [{databaseOwner}].[{objectQualifier}User] usr  where usr.UserID = c.LastUserID)
            else ''	 end,
            LastForumAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}ForumReadTracking] x WHERE x.ForumID=c.ForumID AND x.UserID = @UserID)
             else ''	 end,
            LastTopicAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}TopicReadTracking] y WHERE y.TopicID=c.TopicID AND y.UserID = @UserID)
             else ''	 end,
             c.TopicImage,
            PageIndex = @PageIndex,
            @TotalRows as TotalRows
            from
            TopicIds ti
            inner join [{databaseOwner}].[{objectQualifier}Topic] c
            ON c.TopicID = ti.TopicID
            join [{databaseOwner}].[{objectQualifier}User] lastUser on lastUser.UserID = c.LastUserID
            JOIN [{databaseOwner}].[{objectQualifier}User] b
            ON b.UserID=c.UserID
            join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
            WHERE ti.RowNum between @FirstSelectRowNumber and @LastSelectRowNumber
        order by
            RowNum ASC

end
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}topic_list]
(
    @ForumID int,
    @UserID int = null,
    @Date datetime=null,
    @ToDate datetime=null,
    @PageIndex int = 1,
    @PageSize int = 0,
    @StyledNicks bit = 0,
    @ShowMoved  bit = 0,
    @FindLastRead bit = 0
)
AS
begin
   declare @TotalRows int
   declare @FirstSelectRowNumber int
   declare @LastSelectRowNumber int

   -- find total returned count
   select  @TotalRows = COUNT(c.TopicID)
   FROM [{databaseOwner}].[{objectQualifier}Topic] c
   WHERE c.ForumID = @ForumID
   AND	((c.Priority = 1) OR (c.Priority <=0 AND c.LastPosted>=@Date ))
   AND	c.IsDeleted = 0
    AND	(c.TopicMovedID IS NOT NULL OR c.NumPosts > 0)
    AND
    (@ShowMoved = 1 or (@ShowMoved <> 1 AND  c.TopicMovedID IS NULL))

    select @PageIndex = @PageIndex+1;
    select @FirstSelectRowNumber = (@PageIndex - 1) * @PageSize + 1;
    select @LastSelectRowNumber = (@PageIndex - 1) * @PageSize + @PageSize;

    with TopicIds  as
     (
     select ROW_NUMBER() over (order by tt.[Priority] desc,tt.LastPosted desc) as RowNum, tt.TopicID
     from  [{databaseOwner}].[{objectQualifier}Topic] tt
     where tt.ForumID = @ForumID and (tt.[Priority] = 1 OR (tt.[Priority] <=0 AND tt.LastPosted >=@Date))
      AND	tt.IsDeleted = 0
      AND	((tt.TopicMovedID IS NOT NULL) OR (tt.NumPosts > 0))
      AND
      (@ShowMoved = 1 or (@ShowMoved <> 1 AND  TopicMovedID IS NULL))
      )
      select
            c.ForumID,
            c.TopicID,
            c.Posted,
            LinkTopicID = IsNull(c.TopicMovedID,c.TopicID),
            c.TopicMovedID,
            FavoriteCount = (SELECT COUNT(1) as [FavoriteCount] FROM [{databaseOwner}].[{objectQualifier}FavoriteTopic] WHERE TopicID = IsNull(c.TopicMovedID,c.TopicID)),
            [Subject] = c.Topic,
            c.[Description],
            c.[Status],
            c.[Styles],
            c.UserID,
            Starter = IsNull(c.UserName,b.Name),
            StarterDisplay = IsNull(c.UserDisplayName,b.DisplayName),
            Replies = c.NumPosts - 1,
            NumPostsDeleted = (SELECT COUNT(1) FROM [{databaseOwner}].[{objectQualifier}Message] mes WHERE mes.TopicID = c.TopicID AND mes.IsDeleted = 1 AND mes.IsApproved = 1 AND ((@UserID IS NOT NULL AND mes.UserID = @UserID) OR (@UserID IS NULL)) ),
            [Views] = c.[Views],
            LastPosted = c.LastPosted,
            LastUserID = c.LastUserID,
            LastUserName = (select top 1 usr.Name from [{databaseOwner}].[{objectQualifier}User] usr  where usr.UserID = c.LastUserID),
            LastUserDisplayName = (select top 1 usr.DisplayName from [{databaseOwner}].[{objectQualifier}User] usr  where usr.UserID = c.LastUserID),
            LastMessageID = c.LastMessageID,
            LastTopicID = c.TopicID,
            LinkDate = c.LinkDate,
            TopicFlags = c.Flags,
            c.Priority,
            c.PollID,
            ForumFlags = d.Flags,
            FirstMessage = (SELECT TOP 1 CAST([Message] as nvarchar(1000)) FROM [{databaseOwner}].[{objectQualifier}Message] mes2 where mes2.TopicID = IsNull(c.TopicMovedID,c.TopicID) AND mes2.Position = 0),
            StarterStyle = case(@StyledNicks)
            when 1 then  b.UserStyle
            else ''	 end,
        StarterSuspended = b.Suspended,
        LastUserSuspended = (select top 1 usr.Suspended from [{databaseOwner}].[{objectQualifier}User] usr  where usr.UserID = c.LastUserID),
            LastUserStyle= case(@StyledNicks)
            when 1 then  (select top 1 usr.[UserStyle] from [{databaseOwner}].[{objectQualifier}User] usr  where usr.UserID = c.LastUserID)
            else ''	 end,
            LastForumAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}ForumReadTracking] x WHERE x.ForumID=c.ForumID AND x.UserID = @UserID)
             else ''	 end,
            LastTopicAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}TopicReadTracking] y WHERE y.TopicID=c.TopicID AND y.UserID = @UserID)
             else ''	 end,
             c.TopicImage,
            PageIndex = @PageIndex,
            @TotalRows as TotalRows
            from
            TopicIds ti
            inner join [{databaseOwner}].[{objectQualifier}Topic] c
            ON c.TopicID = ti.TopicID
            JOIN [{databaseOwner}].[{objectQualifier}User] b
            ON b.UserID=c.UserID
            join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
            WHERE ti.RowNum between @FirstSelectRowNumber and @LastSelectRowNumber
        order by
            RowNum ASC
end
GO

create procedure [{databaseOwner}].[{objectQualifier}topic_listmessages](@TopicID int) as
begin
   select
        a.MessageID,
        a.UserID,
        UserName = b.Name,
        UserDisplayName = b.DisplayName,
        a.[Message],
        c.TopicID,
        c.ForumID,
        c.Topic,
        c.Priority,
        c.Description,
        c.Status,
        c.Styles,
        a.Flags,
        c.UserID AS TopicOwnerID,
        Edited = IsNull(a.Edited,a.Posted),
        TopicFlags = c.Flags,
        ForumFlags = d.Flags,
        a.EditReason,
        a.Position,
        a.IsModeratorChanged,
        a.DeleteReason,
        a.BlogPostID,
        c.PollID,
        a.IP,
        a.ReplyTo,
        a.ExternalMessageId,
        a.ReferenceMessageId
    from
        [{databaseOwner}].[{objectQualifier}Message] a
        inner join [{databaseOwner}].[{objectQualifier}User] b on b.UserID = a.UserID
        inner join [{databaseOwner}].[{objectQualifier}Topic] c on a.TopicID = c.TopicID
        inner join [{databaseOwner}].[{objectQualifier}Forum] d on c.ForumID = d.ForumID
    where a.TopicID = @TopicID
end
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}topic_move](@TopicID int,@ForumID int,@ShowMoved bit, @LinkDays int, @UTCTIMESTAMP datetime) AS
begin
        declare @OldForumID int
        declare @newTimestamp datetime
        if @LinkDays > -1
        begin
        SET @newTimestamp = DATEADD(d,@LinkDays,@UTCTIMESTAMP);
        end
    select @OldForumID = ForumID from [{databaseOwner}].[{objectQualifier}Topic] where TopicID = @TopicID

    if @ShowMoved <> 0 begin
        -- delete an old link if exists
        delete from [{databaseOwner}].[{objectQualifier}Topic] where TopicMovedID = @TopicID
        -- create a moved message
        insert into [{databaseOwner}].[{objectQualifier}Topic](ForumID,UserID,UserName,UserDisplayName,Posted,Topic,[Views],Flags,Priority,PollID,TopicMovedID,LastPosted,NumPosts,LinkDate)
        select ForumID,UserID,UserName,UserDisplayName,Posted,Topic,0,Flags,Priority,PollID,@TopicID,LastPosted,0,@newTimestamp
        from [{databaseOwner}].[{objectQualifier}Topic] where TopicID = @TopicID
    end

    -- move the topic
    update [{databaseOwner}].[{objectQualifier}Topic] set ForumID = @ForumID where TopicID = @TopicID

    -- update last posts
    exec [{databaseOwner}].[{objectQualifier}forum_updatelastpost] @OldForumID
    exec [{databaseOwner}].[{objectQualifier}forum_updatelastpost] @ForumID

    -- update stats
    exec [{databaseOwner}].[{objectQualifier}forum_updatestats] @OldForumID
    exec [{databaseOwner}].[{objectQualifier}forum_updatestats] @ForumID

end
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}topic_prune](@BoardID int, @ForumID int=null,@Days int, @PermDelete bit, @UTCTIMESTAMP datetime) as
BEGIN
        DECLARE @c cursor
    DECLARE @TopicID int
    DECLARE @Count int
    SET @Count = 0
    IF @ForumID = 0 SET @ForumID = NULL
    IF @ForumID IS NOT NULL
    BEGIN
        SET @c = cursor for
        SELECT
            TopicID
        FROM [{databaseOwner}].[{objectQualifier}topic] yt
        INNER JOIN
        [{databaseOwner}].[{objectQualifier}Forum] yf
        ON
        yt.ForumID = yf.ForumID
        INNER JOIN
        [{databaseOwner}].[{objectQualifier}Category] yc
        ON
        yf.CategoryID = yc.CategoryID
        WHERE
            yc.BoardID = @BoardID AND
            yt.ForumID = @ForumID AND
            Priority = 0 AND
            (yt.Flags & 512) = 0 AND /* not flagged as persistent */
            datediff(dd,yt.LastPosted,@UTCTIMESTAMP )>@Days
    END
    ELSE BEGIN
        SET @c = CURSOR FOR
        SELECT
            TopicID
        FROM
            [{databaseOwner}].[{objectQualifier}Topic]
        WHERE
            Priority = 0 and
            (Flags & 512) = 0 and					/* not flagged as persistent */
            datediff(dd,LastPosted,@UTCTIMESTAMP )>@Days
    END
    OPEN @c
    FETCH @c into @TopicID
    WHILE @@FETCH_STATUS=0 BEGIN
        IF (@Count % 100 = 1) WAITFOR DELAY '000:00:05'
        EXEC [{databaseOwner}].[{objectQualifier}topic_delete] @TopicID, @PermDelete
        SET @Count = @Count + 1
        FETCH @c INTO @TopicID
    END
    CLOSE @c
    DEALLOCATE @c

    -- This takes forever with many posts...
    --exec [{databaseOwner}].[{objectQualifier}topic_updatelastpost]

    SELECT Count = @Count
END
GO

create procedure [{databaseOwner}].[{objectQualifier}topic_save](
    @ForumID	int,
    @Subject	nvarchar(100),
    @UserID		int,
    @Message	ntext,
    @Description	nvarchar(255)=null,
    @Status 	nvarchar(255)=null,
    @Styles 	nvarchar(255)=null,
    @Priority	smallint,
    @UserName	nvarchar(255)=null,
    @IP			varchar(39),
    @Posted		datetime=null,
    @BlogPostID	nvarchar(50),
    @Flags		int,
    @UTCTIMESTAMP datetime
) as
begin
        declare @TopicID int
    declare @MessageID int, @OverrideDisplayName BIT, @ReplaceName nvarchar(255)

    if @Posted is null set @Posted = @UTCTIMESTAMP
        -- this check is for guest user only to not override replace name
    if (SELECT Name FROM [{databaseOwner}].[{objectQualifier}User] WHERE UserID = @UserID) != @UserName
    begin
    SET @OverrideDisplayName = 1
    end
    SET @ReplaceName = (CASE WHEN @OverrideDisplayName = 1 THEN @UserName ELSE (SELECT DisplayName FROM [{databaseOwner}].[{objectQualifier}User] WHERE UserID = @UserID) END);
    -- create the topic
    insert into [{databaseOwner}].[{objectQualifier}Topic](ForumID,Topic,UserID,Posted,[Views],[Priority],UserName,UserDisplayName,NumPosts, [Description], [Status], [Styles])
    values(@ForumID,@Subject,@UserID,@Posted,0,@Priority,@UserName,@ReplaceName, 0,@Description, @Status, @Styles)

    -- get its id
    set @TopicID = SCOPE_IDENTITY()

    -- add message to the topic
    exec [{databaseOwner}].[{objectQualifier}message_save] @TopicID,@UserID,@Message,@UserName,@IP,@Posted,null,@BlogPostID,null,null,@Flags,@UTCTIMESTAMP,@MessageID output

    select TopicID = @TopicID, MessageID = @MessageID
end
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}topic_updatelastpost]
(@ForumID int=null,@TopicID int=null) as
begin
        if @TopicID is not null
        update [{databaseOwner}].[{objectQualifier}Topic] set
            LastPosted = (select top 1 x.Posted from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and (x.Flags & 24)=16 order by Posted desc),
            LastMessageID = (select top 1 x.MessageID from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and (x.Flags & 24)=16 order by Posted desc),
            LastUserID = (select top 1 x.UserID from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and (x.Flags & 24)=16 order by Posted desc),
            LastUserName = (select top 1 x.UserName from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and (x.Flags & 24)=16 order by Posted desc),
            LastUserDisplayName = (select top 1 x.UserDisplayName from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and (x.Flags & 24)=16 order by Posted desc),
            LastMessageFlags = (select top 1 x.Flags from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and (x.Flags & 24)=16 order by Posted desc)
        where TopicID = @TopicID
    else
        update [{databaseOwner}].[{objectQualifier}Topic] set
            LastPosted = (select top 1 x.Posted from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and (x.Flags & 24)=16 order by Posted desc),
            LastMessageID = (select top 1 x.MessageID from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and (x.Flags & 24)=16 order by Posted desc),
            LastUserID = (select top 1 x.UserID from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and (x.Flags & 24)=16 order by Posted desc),
            LastUserName = (select top 1 x.UserName from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and (x.Flags & 24)=16 order by Posted desc),
            LastUserDisplayName = (select top 1 x.UserDisplayName from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and (x.Flags & 24)=16 order by Posted desc),
            LastMessageFlags = (select top 1 x.Flags from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and (x.Flags & 24)=16 order by Posted desc)
        where TopicMovedID is null
        and (@ForumID is null or ForumID=@ForumID)

    exec [{databaseOwner}].[{objectQualifier}forum_updatelastpost] @ForumID
end
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}user_activity_rank]
(
    @BoardID AS int,
    @DisplayNumber AS int,
    @StartDate AS datetime
)
AS
BEGIN

    DECLARE @GuestUserID int

    SET @GuestUserID =
    (SELECT top 1
        a.UserID
    from
        [{databaseOwner}].[{objectQualifier}User] a
        inner join [{databaseOwner}].[{objectQualifier}UserGroup] b on b.UserID = a.UserID
        inner join [{databaseOwner}].[{objectQualifier}Group] c on b.GroupID = c.GroupID
    where
        a.BoardID = @BoardID and
        (c.Flags & 2)<>0
    )

    SELECT TOP(@DisplayNumber)
        counter.[ID],
        u.[Name],
        counter.[NumOfPosts]
    FROM
        [{databaseOwner}].[{objectQualifier}User] u inner join
        (
            SELECT m.UserID as ID, Count(m.UserID) as NumOfPosts FROM [{databaseOwner}].[{objectQualifier}Message] m
            WHERE m.Posted >= @StartDate
            GROUP BY m.UserID
        ) AS counter ON u.UserID = counter.ID
    WHERE
        u.BoardID = @BoardID and u.UserID != @GuestUserID
    ORDER BY
        NumOfPosts DESC
END
GO

create PROCEDURE [{databaseOwner}].[{objectQualifier}user_addpoints] (@UserID int,@FromUserID int = null, @UTCTIMESTAMP datetime, @Points int) AS
BEGIN
    UPDATE [{databaseOwner}].[{objectQualifier}User] SET Points = Points + @Points WHERE UserID = @UserID

    IF @FromUserID IS NOT NULL
    BEGIN
        declare	@VoteDate datetime
    set @VoteDate = (select top 1 VoteDate from [{databaseOwner}].[{objectQualifier}ReputationVote] where ReputationFromUserID=@FromUserID AND ReputationToUserID=@UserID)
    IF @VoteDate is not null
    begin
          update [{databaseOwner}].[{objectQualifier}ReputationVote] set VoteDate=@UTCTIMESTAMP where VoteDate = @VoteDate AND ReputationFromUserID=@FromUserID AND ReputationToUserID=@UserID
    end
    ELSE
      begin
          insert into [{databaseOwner}].[{objectQualifier}ReputationVote](ReputationFromUserID,ReputationToUserID,VoteDate)
          values (@FromUserID, @UserID, @UTCTIMESTAMP)
      end
    END
END

GO

create procedure [{databaseOwner}].[{objectQualifier}user_approve](@UserID int) as
begin

    declare @CheckEmailID int
    declare @Email nvarchar(255)

    select
        @CheckEmailID = CheckEmailID,
        @Email = Email
    from
        [{databaseOwner}].[{objectQualifier}CheckEmail]
    where
        UserID = @UserID

    -- Update new user email
    update [{databaseOwner}].[{objectQualifier}User] set Email = @Email, Flags = Flags | 2 where UserID = @UserID
    delete [{databaseOwner}].[{objectQualifier}CheckEmail] where CheckEmailID = @CheckEmailID
    select convert(bit,1)
end
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}user_approveall](@BoardID int) as
begin

    DECLARE userslist CURSOR FOR
        SELECT UserID FROM [{databaseOwner}].[{objectQualifier}User] WHERE BoardID=@BoardID AND (Flags & 2)=0
        FOR READ ONLY


    OPEN userslist

    DECLARE @UserID int

    FETCH userslist INTO @UserID

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC [{databaseOwner}].[{objectQualifier}user_approve] @UserID
        FETCH userslist INTO @UserID
    END

    CLOSE userslist

end
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}user_aspnet](@BoardID int,@UserName nvarchar(255),@DisplayName nvarchar(255) = null,@Email nvarchar(255),@ProviderUserKey nvarchar(64),@IsApproved bit,@UTCTIMESTAMP datetime) as
BEGIN
        SET NOCOUNT ON

    DECLARE @UserID int, @RankID int, @approvedFlag int, @TimeZone nvarchar(max)

    SET @approvedFlag = 0;
    IF (@IsApproved = 1) SET @approvedFlag = 2;

    IF EXISTS(SELECT 1 FROM [{databaseOwner}].[{objectQualifier}User] where BoardID=@BoardID and ([ProviderUserKey]=@ProviderUserKey OR [Name] = @UserName))
    BEGIN
        SELECT TOP 1 @UserID = UserID FROM [{databaseOwner}].[{objectQualifier}User] WHERE [BoardID]=@BoardID and ([ProviderUserKey]=@ProviderUserKey OR [Name] = @UserName)

        IF (@DisplayName IS NULL)
        BEGIN
            SELECT TOP 1 @DisplayName = DisplayName FROM [{databaseOwner}].[{objectQualifier}User] WHERE UserID = @UserID
        END

        UPDATE [{databaseOwner}].[{objectQualifier}User] SET
            DisplayName = @DisplayName,
            Email = @Email,
            [ProviderUserKey] = @ProviderUserKey,
            Flags = Flags | @approvedFlag
        WHERE
            UserID = @UserID
    END ELSE
    BEGIN
        SELECT @RankID = RankID from [{databaseOwner}].[{objectQualifier}Rank] where (Flags & 1)<>0 and BoardID=@BoardID

        IF (@DisplayName IS NULL)
        BEGIN
            SET @DisplayName = @UserName
        END

        SET @TimeZone = (SELECT ISNULL([{databaseOwner}].[{objectQualifier}registry_value](N'TimeZone', @BoardID), N'Dateline Standard Time'))

        INSERT INTO [{databaseOwner}].[{objectQualifier}User](BoardID,RankID,[Name],DisplayName,Password,Email,Joined,LastVisit,NumPosts,TimeZone,Flags,ProviderUserKey)
        VALUES(@BoardID,@RankID,@UserName,@DisplayName,'-',@Email,@UTCTIMESTAMP ,@UTCTIMESTAMP ,0, @TimeZone,@approvedFlag,@ProviderUserKey)

        SET @UserID = SCOPE_IDENTITY()
    END

    SELECT UserID=@UserID
END
GO

CREATE PROC [{databaseOwner}].[{objectQualifier}user_pmcount]
    (@UserID int)
AS
BEGIN
        DECLARE @CountIn int
        DECLARE @CountOut int
        DECLARE @CountArchivedIn int
        DECLARE @plimit1 int
        DECLARE @pcount int

      set @plimit1 = (SELECT TOP 1 (c.PMLimit) FROM [{databaseOwner}].[{objectQualifier}User] a
                        JOIN [{databaseOwner}].[{objectQualifier}UserGroup] b
                          ON a.UserID = b.UserID
                            JOIN [{databaseOwner}].[{objectQualifier}Group] c
                              ON b.GroupID = c.GroupID WHERE a.UserID = @UserID ORDER BY c.PMLimit DESC)
      set @pcount = (SELECT TOP 1 c.PMLimit FROM [{databaseOwner}].[{objectQualifier}Rank] c
                        JOIN [{databaseOwner}].[{objectQualifier}User] d
                           ON c.RankID = d.RankID WHERE d.UserID = @UserID ORDER BY c.PMLimit DESC)
      if (@plimit1 > @pcount)
      begin
      set @pcount = @plimit1
      end

    -- get count of pm's in user's sent items

    SELECT
        @CountOut=COUNT(1)
    FROM
        [{databaseOwner}].[{objectQualifier}UserPMessage] a
    INNER JOIN [{databaseOwner}].[{objectQualifier}PMessage] b ON a.PMessageID=b.PMessageID
    WHERE
        (a.Flags & 2)<>0 AND
        b.FromUserID = @UserID
    -- get count of pm's in user's  received items
    SELECT
        @CountIn=COUNT(1)
    FROM
    [{databaseOwner}].[{objectQualifier}PMessage] a
    INNER JOIN
    [{databaseOwner}].[{objectQualifier}UserPMessage] b ON a.PMessageID = b.PMessageID
    WHERE b.IsDeleted = 0
         AND b.IsArchived=0
         -- ToUserID
         AND b.[UserID] = @UserID

    SELECT
        @CountArchivedIn=COUNT(1)
    FROM
    [{databaseOwner}].[{objectQualifier}PMessage] a
    INNER JOIN
    [{databaseOwner}].[{objectQualifier}UserPMessage] b ON a.PMessageID = b.PMessageID
        WHERE
        b.IsArchived <>0 AND
        -- ToUserID
        b.[UserID] = @UserID

    -- return all pm data
    SELECT
        NumberIn = @CountIn,
        NumberOut =  @CountOut,
        NumberTotal = @CountIn + @CountOut + @CountArchivedIn,
        NumberArchived =@CountArchivedIn,
        NumberAllowed = @pcount


END
GO

create procedure [{databaseOwner}].[{objectQualifier}user_delete](@UserID int) as
begin

    declare @GuestUserID	int
    declare @UserName		nvarchar(255)
    declare @UserDisplayName		nvarchar(255)
    declare @GuestCount		int

    select @UserName = Name, @UserDisplayName = DisplayName from [{databaseOwner}].[{objectQualifier}User] where UserID=@UserID

    select top 1
        @GuestUserID = a.UserID
    from
        [{databaseOwner}].[{objectQualifier}User] a
        inner join [{databaseOwner}].[{objectQualifier}UserGroup] b on b.UserID = a.UserID
        inner join [{databaseOwner}].[{objectQualifier}Group] c on b.GroupID = c.GroupID
    where
        (c.Flags & 2)<>0

    select
        @GuestCount = count(1)
    from
        [{databaseOwner}].[{objectQualifier}UserGroup] a
        join [{databaseOwner}].[{objectQualifier}Group] b on b.GroupID=a.GroupID
    where
        (b.Flags & 2)<>0

    if @GuestUserID=@UserID and @GuestCount=1 begin
        return
    end

    update [{databaseOwner}].[{objectQualifier}Message] set UserName=@UserName,UserDisplayName=@UserDisplayName,UserID=@GuestUserID where UserID=@UserID
    update [{databaseOwner}].[{objectQualifier}Topic] set UserName=@UserName,UserDisplayName=@UserDisplayName,UserID=@GuestUserID where UserID=@UserID
    update [{databaseOwner}].[{objectQualifier}Topic] set LastUserName=@UserName,LastUserDisplayName=@UserDisplayName,LastUserID=@GuestUserID where LastUserID=@UserID
    update [{databaseOwner}].[{objectQualifier}Forum] set LastUserName=@UserName,LastUserDisplayName=@UserDisplayName,LastUserID=@GuestUserID where LastUserID=@UserID

    delete from [{databaseOwner}].[{objectQualifier}Active] where UserID=@UserID
    delete from [{databaseOwner}].[{objectQualifier}EventLog] where UserID=@UserID
    delete from [{databaseOwner}].[{objectQualifier}UserPMessage] where UserID=@UserID
    delete from [{databaseOwner}].[{objectQualifier}PMessage] where FromUserID=@UserID AND PMessageID NOT IN (select PMessageID FROM [{databaseOwner}].[{objectQualifier}PMessage])
    -- Delete all the thanks entries associated with this UserID.
    delete from [{databaseOwner}].[{objectQualifier}Thanks] where ThanksFromUserID=@UserID OR ThanksToUserID=@UserID
    -- Delete all the FavoriteTopic entries associated with this UserID.
    delete from [{databaseOwner}].[{objectQualifier}FavoriteTopic] where UserID=@UserID
    -- Delete all the Buddy relations between this user and other users.
    delete from [{databaseOwner}].[{objectQualifier}Buddy] where FromUserID=@UserID
    delete from [{databaseOwner}].[{objectQualifier}Buddy] where ToUserID=@UserID
    -- set messages as from guest so the User can be deleted
    update [{databaseOwner}].[{objectQualifier}PMessage] SET FromUserID = @GuestUserID WHERE FromUserID = @UserID
	delete from [{databaseOwner}].[{objectQualifier}Attachment] where UserID = @UserID
    delete from [{databaseOwner}].[{objectQualifier}CheckEmail] where UserID = @UserID
    delete from [{databaseOwner}].[{objectQualifier}WatchTopic] where UserID = @UserID
    delete from [{databaseOwner}].[{objectQualifier}WatchForum] where UserID = @UserID
    delete from [{databaseOwner}].[{objectQualifier}TopicReadTracking] where UserID = @UserID
    delete from [{databaseOwner}].[{objectQualifier}ForumReadTracking] where UserID = @UserID
	delete from [{databaseOwner}].[{objectQualifier}UserAlbum] where UserID = @UserID
    delete from [{databaseOwner}].[{objectQualifier}ReputationVote] where ReputationFromUserID = @UserID
	delete from [{databaseOwner}].[{objectQualifier}ReputationVote] where ReputationToUserID = @UserID
    delete from [{databaseOwner}].[{objectQualifier}UserGroup] where UserID = @UserID
    -- ABOT CHANGED
    -- Delete UserForums entries Too
    delete from [{databaseOwner}].[{objectQualifier}UserForum] where UserID = @UserID
    delete from [{databaseOwner}].[{objectQualifier}IgnoreUser] where UserID = @UserID OR IgnoredUserID = @UserID
    --END ABOT CHANGED 09.04.2004
    delete from [{databaseOwner}].[{objectQualifier}AdminPageUserAccess] where UserID = @UserID
    delete from [{databaseOwner}].[{objectQualifier}User] where UserID = @UserID
end
GO

create procedure [{databaseOwner}].[{objectQualifier}user_deleteold](@BoardID int, @Days int,@UTCTIMESTAMP datetime) as
begin

    declare @Since datetime

    set @Since = @UTCTIMESTAMP

    delete from [{databaseOwner}].[{objectQualifier}EventLog]  where UserID in(select UserID from [{databaseOwner}].[{objectQualifier}User] where BoardID=@BoardID and IsApproved=0 and datediff(day,Joined,@Since)>@Days)
    delete from [{databaseOwner}].[{objectQualifier}CheckEmail] where UserID in(select UserID from [{databaseOwner}].[{objectQualifier}User] where BoardID=@BoardID and IsApproved=0 and datediff(day,Joined,@Since)>@Days)
    delete from [{databaseOwner}].[{objectQualifier}UserGroup] where UserID in(select UserID from [{databaseOwner}].[{objectQualifier}User] where BoardID=@BoardID and IsApproved=0 and datediff(day,Joined,@Since)>@Days)
    delete from [{databaseOwner}].[{objectQualifier}User] where BoardID=@BoardID and IsApproved=0 and datediff(day,Joined,@Since)>@Days
end
GO

create procedure [{databaseOwner}].[{objectQualifier}user_find](
    @BoardID int,
    @Filter bit,
    @UserName nvarchar(255)=null,
    @Email nvarchar(255)=null,
    @DisplayName nvarchar(255)=null,
    @NotificationType int = null,
    @DailyDigest bit = null,
	@ForumID int = 0
)
AS
begin

    if @ForumID>0
        begin
	        select
                a.*,
                IsAdmin = (select count(1) from [{databaseOwner}].[{objectQualifier}UserGroup] x join [{databaseOwner}].[{objectQualifier}Group] y on y.GroupID=x.GroupID where x.UserID=a.UserID and (y.Flags & 1)<>0)
	        from
                [{databaseOwner}].[{objectQualifier}User] a
				join [{databaseOwner}].[{objectQualifier}vaccess] x  on x.ForumID = @ForumID
	        where
                a.BoardID=@BoardID and
				x.UserID = a.UserID and
                x.ReadAccess <> 0 and
                ((@UserName is not null and a.Name like @UserName) or
                (@Email is not null and Email like @Email) or
                (@DisplayName is not null and a.DisplayName like @DisplayName) or
                (@NotificationType is not null and a.NotificationType = @NotificationType) or
                (@DailyDigest is not null and a.DailyDigest = @DailyDigest))
        end
	else if @Filter<>0
    begin
        if @UserName is not null
            set @UserName = '%' + @UserName + '%'

        if @DisplayName is not null
            set @DisplayName = '%' + @DisplayName + '%'

        select
            a.*,
            IsAdmin = (select count(1) from [{databaseOwner}].[{objectQualifier}UserGroup] x join [{databaseOwner}].[{objectQualifier}Group] y on y.GroupID=x.GroupID where x.UserID=a.UserID and (y.Flags & 1)<>0)
        from
            [{databaseOwner}].[{objectQualifier}User] a
        where
            a.BoardID=@BoardID and
            ((@UserName is not null and a.Name like @UserName) or
            (@Email is not null and Email like @Email) or
            (@DisplayName is not null and a.DisplayName like @DisplayName) or
            (@NotificationType is not null and a.NotificationType = @NotificationType) or
            (@DailyDigest is not null and a.DailyDigest = @DailyDigest))
        order by
            a.Name
    end else
    begin
        select
            a.*,
            IsAdmin = (select count(1) from [{databaseOwner}].[{objectQualifier}UserGroup] x join [{databaseOwner}].[{objectQualifier}Group] y on y.GroupID=x.GroupID where x.UserID=a.UserID and (y.Flags & 1)<>0)
        from
            [{databaseOwner}].[{objectQualifier}User] a
        where
            a.BoardID=@BoardID and
            ((@UserName is not null and a.Name like @UserName) or
            (@Email is not null and Email like @Email) or
            (@DisplayName is not null and a.DisplayName like @DisplayName) or
            (@NotificationType is not null and a.NotificationType = @NotificationType) or
            (@DailyDigest is not null and a.DailyDigest = @DailyDigest))
    end
end
GO

create procedure [{databaseOwner}].[{objectQualifier}user_list](@BoardID int,@UserID int=null,@Approved bit=null,@GroupID int=null,@RankID int=null,@StyledNicks bit = null, @UTCTIMESTAMP datetime) as
begin
    if @UserID is not null
        select
        a.UserID,
        a.BoardID,
        a.ProviderUserKey,
        a.[Name],
        a.[DisplayName],
        a.[Password],
        a.[Email],
        a.Joined,
        a.LastVisit,
        a.IP,
        a.NumPosts,
        a.TimeZone,
        a.Avatar,
        a.[Signature],
        a.AvatarImage,
        a.AvatarImageType,
        a.RankID,
        a.Suspended,
		a.SuspendedReason,
		a.SuspendedBy,
        a.LanguageFile,
        a.ThemeFile,
        a.[PMNotification],
        a.[AutoWatchTopics],
        a.[DailyDigest],
        a.[NotificationType],
        a.[Flags],
		a.[BlockFlags],
        a.[Points],
        a.[IsApproved],
        a.[IsGuest],
        a.[IsCaptchaExcluded],
        a.[IsActiveExcluded],
        a.[IsDST],
        a.[IsDirty],
        a.[Moderated],
        a.[Activity],
        aspnet.Profile_FacebookId,
        aspnet.Profile_GoogleId,
        aspnet.Profile_TwitterId,
        a.[Culture],
            CultureUser = a.Culture,
            RankName = b.Name,
            Style = case(@StyledNicks)
            when 1 then a.UserStyle
            else ''	 end,
            NumDays = datediff(d,a.Joined,@UTCTIMESTAMP )+1,
            NumPostsForum = (select count(1) from [{databaseOwner}].[{objectQualifier}Message] x where x.IsApproved = 1 and x.IsDeleted = 0),
            HasAvatarImage = (select count(1) from [{databaseOwner}].[{objectQualifier}User] x where x.UserID=a.UserID and AvatarImage is not null),
            IsAdmin	= IsNull(c.IsAdmin,0),
            IsGuest	= IsNull(a.Flags & 4,0),
            IsHostAdmin	= IsNull(a.Flags & 1,0),
            IsForumModerator	= IsNull(c.IsForumModerator,0),
            IsModerator		= IsNull(c.IsModerator,0)
        from
            [{databaseOwner}].[{objectQualifier}User] a
            join [{databaseOwner}].[{objectQualifier}AspNetUsers] aspnet on aspnet.Id=a.ProviderUserKey
            join [{databaseOwner}].[{objectQualifier}Rank] b on b.RankID=a.RankID
            left join [{databaseOwner}].[{objectQualifier}vaccess] c on c.UserID=a.UserID
        where
            a.UserID = @UserID and
            a.BoardID = @BoardID and
            IsNull(c.ForumID,0) = 0 and
            (@Approved is null or (@Approved=0 and (a.Flags & 2)=0) or (@Approved=1 and (a.Flags & 2)=2))
        order by
            a.Name

    else if @GroupID is null and @RankID is null
        select
        a.UserID,
        a.BoardID,
        a.ProviderUserKey,
        a.[Name],
        a.[DisplayName],
        a.[Password],
        a.[Email],
        a.Joined,
        a.LastVisit,
        a.IP,
        a.NumPosts,
        a.TimeZone,
        a.Avatar,
        a.[Signature],
        a.AvatarImage,
        a.AvatarImageType,
        a.RankID,
        a.Suspended,
        a.LanguageFile,
        a.ThemeFile,
        a.[PMNotification],
        a.[AutoWatchTopics],
        a.[DailyDigest],
        a.[NotificationType],
        a.[Flags],
		a.[BlockFlags],
        a.[Points],
        a.[IsApproved],
        a.[IsGuest],
        a.[IsCaptchaExcluded],
        a.[IsActiveExcluded],
        a.[IsDST],
        a.[IsDirty],
        a.[Moderated],
        a.[Activity],
        aspnet.Profile_FacebookId,
        aspnet.Profile_GoogleId,
        aspnet.Profile_TwitterId,
        a.[Culture],
            CultureUser = a.Culture,
            Style = case(@StyledNicks)
            when 1 then a.UserStyle
            else ''	 end,
            IsAdmin = (select count(1) from [{databaseOwner}].[{objectQualifier}UserGroup] x join [{databaseOwner}].[{objectQualifier}Group] y on y.GroupID=x.GroupID where x.UserID=a.UserID and (y.Flags & 1)<>0),
            IsGuest	= IsNull(a.Flags & 4,0),
            IsHostAdmin	= IsNull(a.Flags & 1,0),
            RankName = b.Name
        from
            [{databaseOwner}].[{objectQualifier}User] a
            join [{databaseOwner}].[{objectQualifier}AspNetUsers] aspnet on aspnet.Id=a.ProviderUserKey
            join [{databaseOwner}].[{objectQualifier}Rank] b on b.RankID=a.RankID
        where
            a.BoardID = @BoardID and
            (@Approved is null or (@Approved=0 and (a.Flags & 2)=0) or (@Approved=1 and (a.Flags & 2)=2))
        order by
            a.Name
    else
        select
        a.UserID,
        a.BoardID,
        a.ProviderUserKey,
        a.[Name],
        a.[DisplayName],
        a.[Password],
        a.[Email],
        a.Joined,
        a.LastVisit,
        a.IP,
        a.NumPosts,
        a.TimeZone,
        a.Avatar,
        a.[Signature],
        a.AvatarImage,
        a.AvatarImageType,
        a.RankID,
        a.Suspended,
        a.LanguageFile,
        a.ThemeFile,
        a.[PMNotification],
        a.[AutoWatchTopics],
        a.[DailyDigest],
        a.[NotificationType],
        a.[Flags],
        a.[Points],
        a.[IsApproved],
        a.[IsGuest],
        a.[IsCaptchaExcluded],
        a.[IsActiveExcluded],
        a.[IsDST],
        a.[IsDirty],
        a.[Moderated],
        a.[Activity],
        aspnet.Profile_FacebookId,
        aspnet.Profile_GoogleId,
        aspnet.Profile_TwitterId,
        a.[Culture],
            CultureUser = a.Culture,
            IsAdmin = (select count(1) from [{databaseOwner}].[{objectQualifier}UserGroup] x join [{databaseOwner}].[{objectQualifier}Group] y on y.GroupID=x.GroupID where x.UserID=a.UserID and (y.Flags & 1)<>0),
            IsGuest	= IsNull(a.Flags & 4,0),
            IsHostAdmin	= IsNull(a.Flags & 1,0),
            RankName = b.Name,
            Style = case(@StyledNicks)
            when 1 then  a.UserStyle
            else ''	 end
        from
            [{databaseOwner}].[{objectQualifier}User] a
            join [{databaseOwner}].[{objectQualifier}AspNetUsers] aspnet on aspnet.Id=a.ProviderUserKey
            join [{databaseOwner}].[{objectQualifier}Rank] b on b.RankID=a.RankID
        where
            a.BoardID = @BoardID and
            (@Approved is null or (@Approved=0 and (a.Flags & 2)=0) or (@Approved=1 and (a.Flags & 2)=2)) and
            (@GroupID is null or exists(select 1 from [{databaseOwner}].[{objectQualifier}UserGroup] x where x.UserID=a.UserID and x.GroupID=@GroupID)) and
            (@RankID is null or a.RankID=@RankID)
        order by
            a.Name
end
GO

create procedure [{databaseOwner}].[{objectQualifier}user_listmembers](
                @BoardID int,
                @UserID int=null,
                @Approved bit=null,
                @GroupID int=null,
                @RankID int=null,
                @StyledNicks bit = null,
                @Literals nvarchar(255),
                @Exclude bit = null,
                @BeginsWith bit = null,
                @PageIndex int,
                @PageSize int,
                @SortName int = 0,
                @SortRank int = 0,
                @SortJoined int = 0,
                @SortPosts int = 0,
                @SortLastVisit int = 0,
                @NumPosts int = 0,
                @NumPostsCompare int = 0) as
begin
    declare @TotalRows int
    declare @FirstSelectRowNumber int
    declare @LastSelectRowNumber int
    -- find total returned count

    select @TotalRows = count(a.UserID)
    from [{databaseOwner}].[{objectQualifier}User] a
      join [{databaseOwner}].[{objectQualifier}Rank] b
      on b.RankID=a.RankID
      where
       a.BoardID = @BoardID
       and
        (@Approved is null or (@Approved=0 and (a.Flags & 2)=0) or (@Approved=1 and (a.Flags & 2)=2)) and
        (@GroupID is null or exists(select 1 from [{databaseOwner}].[{objectQualifier}UserGroup] x where x.UserID=a.UserID and x.GroupID=@GroupID)) and
        (@RankID is null or a.RankID=@RankID) AND
        -- user is not guest
        ISNULL(a.Flags & 4,0) <> 4
            AND
        (LOWER(a.DisplayName) LIKE CASE
            WHEN (@BeginsWith = 0 AND @Literals IS NOT NULL AND LEN(@Literals) > 0) THEN '%' + LOWER(@Literals) + '%'
            WHEN (@BeginsWith = 1 AND @Literals IS NOT NULL AND LEN(@Literals) > 0) THEN LOWER(@Literals) + '%'
            ELSE '%' END
            or
         LOWER(a.Name) LIKE CASE
            WHEN (@BeginsWith = 0 AND @Literals IS NOT NULL AND LEN(@Literals) > 0) THEN '%' + LOWER(@Literals) + '%'
            WHEN (@BeginsWith = 1 AND @Literals IS NOT NULL AND LEN(@Literals) > 0) THEN LOWER(@Literals) + '%'
            ELSE '%' END)
        and
        (a.NumPosts >= (case
        when @NumPostsCompare = 3 then  @NumPosts end)
        OR a.NumPosts <= (case
        when @NumPostsCompare = 2 then @NumPosts end) OR
        a.NumPosts = (case
        when @NumPostsCompare = 1 then @NumPosts end));

    select @PageIndex = @PageIndex+1;
    select @FirstSelectRowNumber = (@PageIndex - 1) * @PageSize + 1;
    select @LastSelectRowNumber = (@PageIndex - 1) * @PageSize + @PageSize;

    with UserIds  as
     (
     select ROW_NUMBER() over (order by    (case
        when @SortName = 2 then a.[Name] end) DESC,
        (case
        when @SortName = 1 then a.[Name] end) ASC,
        (case
        when @SortRank = 2 then a.RankID end) DESC,
        (case
        when @SortRank = 1 then a.RankID end) ASC,
        (case
        when @SortJoined = 2 then a.Joined end) DESC,
        (case
        when @SortJoined = 1 then a.Joined end) ASC,
        (case
        when @SortLastVisit = 2 then a.LastVisit end) DESC,
        (case
        when @SortLastVisit = 1 then a.LastVisit end) ASC,
        (case
         when @SortPosts = 2 then a.NumPosts end) DESC,
        (case
         when @SortPosts = 1 then a.NumPosts end) ASC ) as RowNum, a.UserID
     from [{databaseOwner}].[{objectQualifier}User] a
            join [{databaseOwner}].[{objectQualifier}Rank] b  on b.RankID=a.RankID
     where
       a.BoardID = @BoardID
       and
        (@Approved is null or (@Approved=0 and (a.Flags & 2)=0) or (@Approved=1 and (a.Flags & 2)=2)) and
        (@GroupID is null or exists(select 1 from [{databaseOwner}].[{objectQualifier}UserGroup] x where x.UserID=a.UserID and x.GroupID=@GroupID)) and
        (@RankID is null or a.RankID=@RankID) AND
        -- user is not guest
        ISNULL(a.Flags & 4,0) <> 4
            AND
        (LOWER(a.DisplayName) LIKE CASE
            WHEN (@BeginsWith = 0 AND @Literals IS NOT NULL AND LEN(@Literals) > 0) THEN '%' + LOWER(@Literals) + '%'
            WHEN (@BeginsWith = 1 AND @Literals IS NOT NULL AND LEN(@Literals) > 0) THEN LOWER(@Literals) + '%'
            ELSE '%' END
            or
         LOWER(a.Name) LIKE CASE
            WHEN (@BeginsWith = 0 AND @Literals IS NOT NULL AND LEN(@Literals) > 0) THEN '%' + LOWER(@Literals) + '%'
            WHEN (@BeginsWith = 1 AND @Literals IS NOT NULL AND LEN(@Literals) > 0) THEN LOWER(@Literals) + '%'
            ELSE '%' END)
        and
        (a.NumPosts >= (case
        when @NumPostsCompare = 3 then  @NumPosts end)
        OR a.NumPosts <= (case
        when @NumPostsCompare = 2 then @NumPosts end) OR
        a.NumPosts = (case
        when @NumPostsCompare = 1 then @NumPosts end))
      )
      select
            a.*,
            CultureUser = a.Culture,
            IsAdmin = (select COUNT(1) from [{databaseOwner}].[{objectQualifier}UserGroup] x join [{databaseOwner}].[{objectQualifier}Group] y on y.GroupID=x.GroupID where x.UserID=a.UserID and (y.Flags & 1)<>0),
            IsHostAdmin	= ISNULL(a.Flags & 1,0),
            b.RankID,
            RankName = b.Name,
            Style = case(@StyledNicks)
            when 1 then  a.UserStyle
            else ''	 end,
            TotalCount =  @TotalRows
            from
            UserIds ti inner join
            [{databaseOwner}].[{objectQualifier}User] a
            on a.UserID = ti.UserID
            join [{databaseOwner}].[{objectQualifier}Rank] b  on b.RankID=a.RankID

    where ti.RowNum between @FirstSelectRowNumber and @LastSelectRowNumber
        order by
            RowNum ASC;
end
GO

create procedure [{databaseOwner}].[{objectQualifier}user_nntp](@BoardID int,@UserName nvarchar(255),@Email nvarchar(255),@TimeZone int, @UTCTIMESTAMP datetime) as
begin

    declare @UserID int
	declare @TimeZonetmp nvarchar(max)

    set @UserName = @UserName + ' (NNTP)'

    select
        @UserID=UserID
    from
        [{databaseOwner}].[{objectQualifier}User]
    where
        BoardID=@BoardID and
        Name=@UserName

    SET @TimeZonetmp = (SELECT ISNULL([{databaseOwner}].[{objectQualifier}registry_value](N'TimeZone', @BoardID), N'Dateline Standard Time'))

    if @@ROWCOUNT<1
    begin
        exec [{databaseOwner}].[{objectQualifier}user_save] null,@BoardID,@UserName,@UserName,@Email,@TimeZonetmp,null,null,null,1, null, 0, @UTCTIMESTAMP

        -- The next one is not safe, but this procedure is only used for testing
        select @UserID = @@IDENTITY
    end

    select UserID=@UserID
end
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}user_removepoints] (@UserID int, @FromUserID int = null, @UTCTIMESTAMP datetime, @Points int) AS
BEGIN

    UPDATE [{databaseOwner}].[{objectQualifier}User] SET Points = Points - @Points WHERE UserID = @UserID

    IF @FromUserID IS NOT NULL
    BEGIN
        declare	@VoteDate datetime
    set @VoteDate = (select top 1 VoteDate from [{databaseOwner}].[{objectQualifier}ReputationVote] where ReputationFromUserID=@FromUserID AND ReputationToUserID=@UserID)
    IF @VoteDate is not null
    begin
          update [{databaseOwner}].[{objectQualifier}ReputationVote] set VoteDate=@UTCTIMESTAMP where VoteDate = @VoteDate AND ReputationFromUserID=@FromUserID AND ReputationToUserID=@UserID
    end
    ELSE
      begin
          insert into [{databaseOwner}].[{objectQualifier}ReputationVote](ReputationFromUserID,ReputationToUserID,VoteDate)
          values (@FromUserID, @UserID, @UTCTIMESTAMP)
      end
    END
END
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}user_save](
    @UserID				int,
    @BoardID			int,
    @UserName			nvarchar(255) = null,
    @DisplayName		nvarchar(255) = null,
    @Email				nvarchar(255) = null,
    @TimeZone			nvarchar(max),
    @LanguageFile		nvarchar(50) = null,
    @Culture		    varchar(10) = null,
    @ThemeFile			nvarchar(50) = null,
    @Approved			bit = null,
    @ProviderUserKey	nvarchar(64) = null,
    @HideUser           bit = null,
    @UTCTIMESTAMP datetime)
AS
begin

    declare @RankID int
    declare @Flags int
    declare @OldDisplayName nvarchar(255)

    if @HideUser is null SET @HideUser = 0

    if @UserID is null or @UserID<1 begin

        if @Approved<>0 set @Flags = @Flags | 2
        if @Email = '' set @Email = null

        select @RankID = RankID from [{databaseOwner}].[{objectQualifier}Rank] where (Flags & 1)<>0 and BoardID=@BoardID

        insert into [{databaseOwner}].[{objectQualifier}User](BoardID,RankID,[Name],DisplayName,Password,Email,Joined,LastVisit,NumPosts,TimeZone,Flags,ProviderUserKey)
        values(@BoardID,@RankID,@UserName,@DisplayName,'-',@Email,@UTCTIMESTAMP ,@UTCTIMESTAMP ,0,@TimeZone, @Flags,@ProviderUserKey)

        set @UserID = SCOPE_IDENTITY()

        insert into [{databaseOwner}].[{objectQualifier}UserGroup](UserID,GroupID) select @UserID,GroupID from [{databaseOwner}].[{objectQualifier}Group] where BoardID=@BoardID and (Flags & 4)<>0
    end
    else begin
        SELECT @Flags = Flags, @OldDisplayName = DisplayName FROM [{databaseOwner}].[{objectQualifier}User] where UserID = @UserID

        -- set user dirty
        set @Flags = @Flags	| 64

        IF ((@HideUser<>0) AND ((@Flags & 16) <> 16))
        SET @Flags = @Flags | 16
        ELSE IF ((@HideUser=0) AND ((@Flags & 16) = 16))
        SET @Flags = @Flags ^ 16

        update [{databaseOwner}].[{objectQualifier}User] set
            TimeZone = @TimeZone,
            LanguageFile = @LanguageFile,
            ThemeFile = @ThemeFile,
            Culture = @Culture,
            Flags = (CASE WHEN @Flags<>Flags THEN  @Flags ELSE Flags END),
            DisplayName = (CASE WHEN (@DisplayName is not null) THEN  @DisplayName ELSE DisplayName END),
            Email = (CASE WHEN (@Email is not null) THEN  @Email ELSE Email END)
        where UserID = @UserID
        -- here we sync a new display name everywhere
        if (@DisplayName IS NOT NULL AND COALESCE(@OldDisplayName,'') != COALESCE(@DisplayName,''))
        begin
        -- sync display names everywhere - can run a long time on large forums
        update [{databaseOwner}].[{objectQualifier}Forum] set LastUserDisplayName = @DisplayName where LastUserID = @UserID  AND (LastUserDisplayName IS NULL OR LastUserDisplayName = @OldDisplayName)
        update [{databaseOwner}].[{objectQualifier}Topic] set LastUserDisplayName = @DisplayName where LastUserID = @UserID AND (LastUserDisplayName IS NULL OR LastUserDisplayName = @OldDisplayName)
        update [{databaseOwner}].[{objectQualifier}Topic] set UserDisplayName = @DisplayName where UserID = @UserID AND (UserDisplayName IS NULL OR UserDisplayName = @OldDisplayName)
        update [{databaseOwner}].[{objectQualifier}Message] set UserDisplayName = @DisplayName where UserID = @UserID AND (UserDisplayName IS NULL OR UserDisplayName = @OldDisplayName)
        end

    end
end
GO

create procedure [{databaseOwner}].[{objectQualifier}user_setrole](@BoardID int,@ProviderUserKey nvarchar(64),@Role nvarchar(255)) as
begin

    declare @UserID int, @GroupID int

    select @UserID=UserID from [{databaseOwner}].[{objectQualifier}User] where BoardID=@BoardID and ProviderUserKey=@ProviderUserKey

    if @Role is null
    begin
        delete from [{databaseOwner}].[{objectQualifier}UserGroup] where UserID=@UserID
    end else
    begin
        if not exists(select 1 from [{databaseOwner}].[{objectQualifier}Group] where BoardID=@BoardID and Name=@Role)
        begin
            insert into [{databaseOwner}].[{objectQualifier}Group](Name,BoardID,Flags)
            values(@Role,@BoardID,0);
            set @GroupID = SCOPE_IDENTITY()

            insert into [{databaseOwner}].[{objectQualifier}ForumAccess](GroupID,ForumID,AccessMaskID)
            select
                @GroupID,
                a.ForumID,
                min(a.AccessMaskID)
            from
                [{databaseOwner}].[{objectQualifier}ForumAccess] a
                join [{databaseOwner}].[{objectQualifier}Group] b on b.GroupID=a.GroupID
            where
                b.BoardID=@BoardID and
                (b.Flags & 4)=4
            group by
                a.ForumID
        end else
        begin
            select @GroupID = GroupID from [{databaseOwner}].[{objectQualifier}Group] where BoardID=@BoardID and Name=@Role
        end
        -- user already can be in the group even if Role isn't null, an extra check is required
        if not exists(select 1 from [{databaseOwner}].[{objectQualifier}UserGroup] where UserID=@UserID and GroupID=@GroupID)
        begin
        insert into [{databaseOwner}].[{objectQualifier}UserGroup](UserID,GroupID) values(@UserID,@GroupID)
        end
    end
end
GO

create procedure [{databaseOwner}].[{objectQualifier}user_upgrade](@UserID int) as
begin

    declare @RankID			int
    declare @Flags			int
    declare @MinPosts		int
    declare @NumPosts		int
    declare @BoardId		int
    declare @RankBoardID	int

    -- Get user and rank information
    select
        @RankID = b.RankID,
        @Flags = b.Flags,
        @MinPosts = b.MinPosts,
        @NumPosts = a.NumPosts,
        @BoardId = a.BoardID
    from
        [{databaseOwner}].[{objectQualifier}User] a
        inner join [{databaseOwner}].[{objectQualifier}Rank] b on b.RankID = a.RankID
    where
        a.UserID = @UserID

    -- If user isn't member of a ladder rank, exit
    if (@Flags & 2) = 0 return

    -- retrieve board current user's rank beling to
    select @RankBoardID = BoardID
    from   [{databaseOwner}].[{objectQualifier}Rank]
    where  RankID = @RankID

    -- does user have rank from his board?
    IF @RankBoardID <> @BoardId begin
        -- get highest rank user can get
        select top 1
               @RankID = RankID
        from   [{databaseOwner}].[{objectQualifier}Rank]
        where  BoardID = @BoardId
               and (Flags & 2) = 2
               and MinPosts <= @NumPosts
        order by
               MinPosts desc
    end
    else begin
        -- See if user got enough posts for next ladder group
        select top 1
            @RankID = RankID
        from
            [{databaseOwner}].[{objectQualifier}Rank]
        where
            BoardID = @BoardId and
            (Flags & 2) = 2 and
            MinPosts <= @NumPosts and
            MinPosts > @MinPosts
        order by
            MinPosts
    end

    if @@ROWCOUNT=1
        update [{databaseOwner}].[{objectQualifier}User] set RankID = @RankID where UserID = @UserID
end
GO

create procedure [{databaseOwner}].[{objectQualifier}usergroup_save](@UserID int,@GroupID int,@Member bit) as
begin

    if @Member=0
    begin
        delete from [{databaseOwner}].[{objectQualifier}UserGroup] where UserID=@UserID and GroupID=@GroupID
    end
    else
    begin
        insert into [{databaseOwner}].[{objectQualifier}UserGroup](UserID,GroupID)
        select @UserID,@GroupID
        where not exists(select 1 from [{databaseOwner}].[{objectQualifier}UserGroup] where UserID=@UserID and GroupID=@GroupID)
        UPDATE [{databaseOwner}].[{objectQualifier}User] SET UserStyle= ISNULL(( SELECT TOP 1 f.Style FROM [{databaseOwner}].[{objectQualifier}UserGroup] e
        join [{databaseOwner}].[{objectQualifier}Group] f on f.GroupID=e.GroupID WHERE e.UserID=@UserID AND f.Style IS NOT NULL ORDER BY f.SortOrder), (SELECT TOP 1 r.Style FROM [{databaseOwner}].[{objectQualifier}Rank] r where r.RankID = [{databaseOwner}].[{objectQualifier}User].RankID))
        WHERE UserID = @UserID
    end
end
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}message_deleteundelete](@MessageID int, @isModeratorChanged bit, @DeleteReason nvarchar(100), @isDeleteAction int) as
begin

    declare @TopicID		int
    declare @ForumID		int
    declare @MessageCount	int
    declare @LastMessageID	int
    declare @UserID			int

    -- Find TopicID and ForumID
    select @TopicID=b.TopicID,@ForumID=b.ForumID,@UserID = a.UserID
    from
        [{databaseOwner}].[{objectQualifier}Message] a
        inner join [{databaseOwner}].[{objectQualifier}Topic] b on b.TopicID=a.TopicID
    where
        a.MessageID=@MessageID

    -- Update LastMessageID in Topic and Forum
    update [{databaseOwner}].[{objectQualifier}Topic] set
        LastPosted = null,
        LastMessageID = null,
        LastUserID = null,
        LastUserName = null,
        LastUserDisplayName = null,
        LastMessageFlags = null
    where LastMessageID = @MessageID

    update [{databaseOwner}].[{objectQualifier}Forum] set
        LastPosted = null,
        LastTopicID = null,
        LastMessageID = null,
        LastUserID = null,
        LastUserName = null,
        LastUserDisplayName = null
    where LastMessageID = @MessageID

    -- "Delete" message
    update [{databaseOwner}].[{objectQualifier}Message]
     set IsModeratorChanged = @isModeratorChanged, DeleteReason = @DeleteReason, Flags = Flags ^ 8
     where MessageID = @MessageID and ((Flags & 8) <> @isDeleteAction*8)

    -- update num posts for user now that the delete/undelete status has been toggled...
    if exists(select top 1 1 from [{databaseOwner}].[{objectQualifier}Forum] where ForumID=@ForumID and (Flags & 4)=0)
    begin
	    UPDATE [{databaseOwner}].[{objectQualifier}User] SET NumPosts = (SELECT count(MessageID) FROM [{databaseOwner}].[{objectQualifier}Message] WHERE UserID = @UserID AND IsDeleted = 0 AND IsApproved = 1) WHERE UserID = @UserID
	end

    -- Delete topic if there are no more messages
    select @MessageCount = count(1) from [{databaseOwner}].[{objectQualifier}Message] where TopicID = @TopicID and IsDeleted=0
    if @MessageCount=0 exec [{databaseOwner}].[{objectQualifier}topic_delete] @TopicID
    -- update lastpost
    exec [{databaseOwner}].[{objectQualifier}topic_updatelastpost] @ForumID,@TopicID
    exec [{databaseOwner}].[{objectQualifier}forum_updatestats] @ForumID
    -- update topic numposts
    update [{databaseOwner}].[{objectQualifier}Topic] set
        NumPosts = (select count(1) from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and x.IsApproved = 1 and x.IsDeleted = 0 )
    where TopicID = @TopicID
end
GO

create procedure [{databaseOwner}].[{objectQualifier}topic_create_by_message] (
    @MessageID int,
    @ForumID	int,
    @Subject	nvarchar(100),
    @UTCTIMESTAMP datetime
) as
begin

declare		@UserID		int
declare		@Posted		datetime

set @UserID = (select UserID from [{databaseOwner}].[{objectQualifier}message] where MessageID =  @MessageID)
set  @Posted  = (select  posted from [{databaseOwner}].[{objectQualifier}message] where MessageID =  @MessageID)


    declare @TopicID int
    --declare @MessageID int

    if @Posted is null set @Posted = @UTCTIMESTAMP

    insert into [{databaseOwner}].[{objectQualifier}Topic](ForumID,Topic,UserID,Posted,[Views],Priority,PollID,UserName,NumPosts)
    values(@ForumID,@Subject,@UserID,@Posted,0,0,null,null,0)

    set @TopicID = @@IDENTITY
--	exec [{databaseOwner}].[{objectQualifier}message_save] @TopicID,@UserID,@Message,@UserName,@IP,@Posted,null,@Flags,@MessageID output
    select TopicID = @TopicID, MessageID = @MessageID
END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}message_move] (@MessageID int, @MoveToTopic int) AS
BEGIN
    DECLARE
    @Position int,
    @ReplyToID int,
    @OldTopicID int,
    @OldForumID int

    declare @NewForumID		int
    declare @MessageCount	int
    declare @LastMessageID	int

    -- Find TopicID and ForumID
--	select @OldTopicID=b.TopicID,@ForumID=b.ForumID from [{databaseOwner}].[{objectQualifier}Message] a,{objectQualifier}Topic b where a.MessageID=@MessageID and b.TopicID=a.TopicID

SET 	@NewForumID =   (SELECT TOP(1) ForumID
                        FROM [{databaseOwner}].[{objectQualifier}Topic]
                        WHERE (TopicID = @MoveToTopic))

SET 	@OldTopicID = 	(SELECT TOP(1) TopicID
                        FROM [{databaseOwner}].[{objectQualifier}Message]
                        WHERE (MessageID = @MessageID))

SET 	@OldForumID =   (SELECT TOP(1) ForumID
                        FROM [{databaseOwner}].[{objectQualifier}Topic]
                        WHERE (TopicID = @OldTopicID))

SET	@ReplyToID =    (SELECT TOP(1) MessageID
                    FROM [{databaseOwner}].[{objectQualifier}Message]
                    WHERE ([Position] = 0) AND (TopicID = @MoveToTopic))

DECLARE @Posted DATETIME
SET @Posted = (SELECT TOP(1) Posted FROM [{databaseOwner}].[{objectQualifier}Message] AS Msg WHERE MessageID = @MessageID)

SET	@Position = (SELECT TOP(1) MAX([Position]) + 1 AS Expr1
                FROM [{databaseOwner}].[{objectQualifier}Message]
                WHERE (TopicID = @MoveToTopic) and Posted < @Posted)

if @Position is null  set @Position = 0

update [{databaseOwner}].[{objectQualifier}Message] set
        Position = Position+1
     WHERE     (TopicID = @MoveToTopic) and Posted > @Posted

update [{databaseOwner}].[{objectQualifier}Message] set
        Position = Position-1
     WHERE     (TopicID = @OldTopicID) and Posted > @Posted

    -- Update LastMessageID in Topic and Forum
    update [{databaseOwner}].[{objectQualifier}Topic] set
        LastPosted = null,
        LastMessageID = null,
        LastUserID = null,
        LastUserName = null,
        LastMessageFlags = null,
        LastUserDisplayName = null
    where LastMessageID = @MessageID

    update [{databaseOwner}].[{objectQualifier}Forum] set
        LastPosted = null,
        LastTopicID = null,
        LastMessageID = null,
        LastUserID = null,
        LastUserName = null,
        LastUserDisplayName = null
    where LastMessageID = @MessageID


    if (@Position = 0)
	begin
	    update [{databaseOwner}].[{objectQualifier}Message] set
		    ReplyTo = @MessageID
        WHERE
		    TopicID = @MoveToTopic and ReplyTo is NULL

		set @ReplyToID = NULL
    end

    UPDATE [{databaseOwner}].[{objectQualifier}Message] SET
    TopicID = @MoveToTopic,
    ReplyTo = @ReplyToID,
    [Position] = @Position
    WHERE  MessageID = @MessageID

    -- Delete topic if there are no more messages
    select @MessageCount = count(1) from [{databaseOwner}].[{objectQualifier}Message] where TopicID = @OldTopicID and IsDeleted=0
    if @MessageCount=0 exec [{databaseOwner}].[{objectQualifier}topic_delete] @OldTopicID

    -- update lastpost
    exec [{databaseOwner}].[{objectQualifier}topic_updatelastpost] @OldForumID,@OldTopicID
    exec [{databaseOwner}].[{objectQualifier}topic_updatelastpost] @NewForumID,@MoveToTopic

    -- update topic numposts
    update [{databaseOwner}].[{objectQualifier}Topic] set
        NumPosts = (select count(1) from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and x.IsApproved = 1 and x.IsDeleted = 0)
    where TopicID = @OldTopicID
    update [{databaseOwner}].[{objectQualifier}Topic] set
        NumPosts = (select count(1) from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=[{databaseOwner}].[{objectQualifier}Topic].TopicID and x.IsApproved = 1 and x.IsDeleted = 0)
    where TopicID = @MoveToTopic

    exec [{databaseOwner}].[{objectQualifier}forum_updatelastpost] @NewForumID
    exec [{databaseOwner}].[{objectQualifier}forum_updatestats] @NewForumID
    exec [{databaseOwner}].[{objectQualifier}forum_updatelastpost] @OldForumID
    exec [{databaseOwner}].[{objectQualifier}forum_updatestats] @OldForumID

END
GO

create proc [{databaseOwner}].[{objectQualifier}forum_resync]
    @BoardID int,
    @ForumID int = null
AS
begin

    if (@ForumID is null) begin
        declare curForums cursor for
            select
                a.ForumID
            from
                [{databaseOwner}].[{objectQualifier}Forum] a
                JOIN [{databaseOwner}].[{objectQualifier}Category] b on a.CategoryID=b.CategoryID
                JOIN [{databaseOwner}].[{objectQualifier}Board] c on b.BoardID = c.BoardID
            where
                c.BoardID=@BoardID

        open curForums

        -- cycle through forums
        fetch next from curForums into @ForumID
        while @@FETCH_STATUS = 0
        begin
            --update statistics
            exec [{databaseOwner}].[{objectQualifier}forum_updatestats] @ForumID
            --update last post
            exec [{databaseOwner}].[{objectQualifier}forum_updatelastpost] @ForumID

            fetch next from curForums into @ForumID
        end
        close curForums
        deallocate curForums
    end
    else begin
        --update statistics
        exec [{databaseOwner}].[{objectQualifier}forum_updatestats] @ForumID
        --update last post
        exec [{databaseOwner}].[{objectQualifier}forum_updatelastpost] @ForumID
    end
end
GO

create proc [{databaseOwner}].[{objectQualifier}board_resync]
    @BoardID int = null
as
begin

    if (@BoardID is null) begin
        declare curBoards cursor for
            select BoardID from	[{databaseOwner}].[{objectQualifier}Board]

        open curBoards

        -- cycle through forums
        fetch next from curBoards into @BoardID
        while @@FETCH_STATUS = 0
        begin
            --resync board forums
            exec [{databaseOwner}].[{objectQualifier}forum_resync] @BoardID

            fetch next from curBoards into @BoardID
        end
        close curBoards
        deallocate curBoards
    end
    else begin
        --resync board forums
        exec [{databaseOwner}].[{objectQualifier}forum_resync] @BoardID
    end
end
GO

-- polls

CREATE procedure [{databaseOwner}].[{objectQualifier}poll_remove](
    @PollID int, @BoardID int = null)
as
begin
    -- delete vote records first
    delete from [{databaseOwner}].[{objectQualifier}PollVote] where PollID = @PollID
    -- delete choices
    delete from [{databaseOwner}].[{objectQualifier}Choice] where PollID = @PollID

    -- update topics
    Update [{databaseOwner}].[{objectQualifier}Topic] set PollID = NULL where PollID = @PollID

    -- delete poll
    delete from [{databaseOwner}].[{objectQualifier}Poll] where PollID = @PollID
end
GO

-- medals

CREATE proc [{databaseOwner}].[{objectQualifier}group_medal_list]
    @GroupID int = null,
    @MedalID int = null
as begin

    select
        a.[MedalID],
        a.[Name],
        a.[MedalURL],
        a.[RibbonURL],
        a.[SmallMedalURL],
        a.[SmallRibbonURL],
        a.[SmallMedalWidth],
        a.[SmallMedalHeight],
        a.[SmallRibbonWidth],
        a.[SmallRibbonHeight],
        b.[SortOrder],
        a.[Flags],
        c.[Name] as [GroupName],
        b.[GroupID],
        isnull(b.[Message],a.[Message]) as [Message],
        b.[Message] as [MessageEx],
        b.[Hide],
        b.[OnlyRibbon],
        b.[SortOrder] as CurrentSortOrder
    from
        [{databaseOwner}].[{objectQualifier}Medal] a
        inner join [{databaseOwner}].[{objectQualifier}GroupMedal] b on b.[MedalID] = a.[MedalID]
        inner join [{databaseOwner}].[{objectQualifier}Group] c on  c.[GroupID] = b.[GroupID]
    where
        (@GroupID is null or b.[GroupID] = @GroupID) and
        (@MedalID is null or b.[MedalID] = @MedalID)
    order by
        c.[Name] ASC,
        b.[SortOrder] ASC

end
GO

CREATE proc [{databaseOwner}].[{objectQualifier}medal_delete]
    @BoardID	int = null,
    @MedalID	int = null,
    @Category	nvarchar(50) = null
as begin

    if not @MedalID is null begin
        delete from [{databaseOwner}].[{objectQualifier}GroupMedal] where [MedalID] = @MedalID
        delete from [{databaseOwner}].[{objectQualifier}UserMedal] where [MedalID] = @MedalID

        delete from [{databaseOwner}].[{objectQualifier}Medal] where [MedalID]=@MedalID
    end
    else if not @Category is null and not @BoardID is null begin
        delete from [{databaseOwner}].[{objectQualifier}GroupMedal]
            where [MedalID] in (SELECT [MedalID] FROM [{databaseOwner}].[{objectQualifier}Medal] where [Category]=@Category and [BoardID]=@BoardID)

        delete from [{databaseOwner}].[{objectQualifier}UserMedal]
            where [MedalID] in (SELECT [MedalID] FROM [{databaseOwner}].[{objectQualifier}Medal] where [Category]=@Category and [BoardID]=@BoardID)

        delete from [{databaseOwner}].[{objectQualifier}Medal] where [Category]=@Category
    end
    else if not @BoardID is null begin
        delete from [{databaseOwner}].[{objectQualifier}GroupMedal]
            where [MedalID] in (SELECT [MedalID] FROM [{databaseOwner}].[{objectQualifier}Medal] where [BoardID]=@BoardID)

        delete from [{databaseOwner}].[{objectQualifier}UserMedal]
            where [MedalID] in (SELECT [MedalID] FROM [{databaseOwner}].[{objectQualifier}Medal] where [BoardID]=@BoardID)

        delete from [{databaseOwner}].[{objectQualifier}Medal] where [BoardID]=@BoardID
    end

end
GO

CREATE proc [{databaseOwner}].[{objectQualifier}medal_listusers]
    @MedalID	int
as begin
        (select
        a.UserID, a.Name
    from
        [{databaseOwner}].[{objectQualifier}User] a
        inner join [{databaseOwner}].[{objectQualifier}UserMedal] b on a.[UserID] = b.[UserID]
    where
        b.[MedalID]=@MedalID)

    union

    (select
        a.UserID, a.Name
    from
        [{databaseOwner}].[{objectQualifier}User] a
        inner join [{databaseOwner}].[{objectQualifier}UserGroup] b on a.[UserID] = b.[UserID]
        inner join [{databaseOwner}].[{objectQualifier}GroupMedal] c on b.[GroupID] = c.[GroupID]
    where
        c.[MedalID]=@MedalID)


end
GO

create proc [{databaseOwner}].[{objectQualifier}medal_resort]
    @BoardID int,@MedalID int,@Move int
as
begin
        declare @Position int
    declare @Category nvarchar(50)

    select
        @Position=[SortOrder],
        @Category=[Category]
    from
        [{databaseOwner}].[{objectQualifier}Medal]
    where
        [BoardID]=@BoardID and [MedalID]=@MedalID

    if (@Position is null) return

    if (@Move > 0) begin
        update
            [{databaseOwner}].[{objectQualifier}Medal]
        set
            [SortOrder]=[SortOrder]-1
        where
            [BoardID]=@BoardID and
            [Category]=@Category and
            [SortOrder] between @Position and (@Position + @Move) and
            [SortOrder] between 1 and 255
    end
    else if (@Move < 0) begin
        update
            [{databaseOwner}].[{objectQualifier}Medal]
        set
            [SortOrder]=[SortOrder]+1
        where
            BoardID=@BoardID and
            [Category]=@Category and
            [SortOrder] between (@Position+@Move) and @Position and
            [SortOrder] between 0 and 254
    end

    SET @Position = @Position + @Move

    if (@Position>255) SET @Position = 255
    else if (@Position<0) SET @Position = 0

    update [{databaseOwner}].[{objectQualifier}Medal]
        set [SortOrder]=@Position
        where [BoardID]=@BoardID and
            [MedalID]=@MedalID
end
GO

CREATE proc [{databaseOwner}].[{objectQualifier}medal_save]
    @BoardID int = NULL,
    @MedalID int = NULL,
    @Name nvarchar(100),
    @Description nvarchar(max),
    @Message nvarchar(100),
    @Category nvarchar(50) = NULL,
    @MedalURL nvarchar(250),
    @RibbonURL nvarchar(250) = NULL,
    @SmallMedalURL nvarchar(250),
    @SmallRibbonURL nvarchar(250) = NULL,
    @SmallMedalWidth smallint,
    @SmallMedalHeight smallint,
    @SmallRibbonWidth smallint = NULL,
    @SmallRibbonHeight smallint = NULL,
    @SortOrder tinyint = 255,
    @Flags int = 0
as begin
        if @MedalID is null begin
        insert into [{databaseOwner}].[{objectQualifier}Medal]
            ([BoardID],[Name],[Description],[Message],[Category],
            [MedalURL],[RibbonURL],[SmallMedalURL],[SmallRibbonURL],
            [SmallMedalWidth],[SmallMedalHeight],[SmallRibbonWidth],[SmallRibbonHeight],
            [SortOrder],[Flags])
        values
            (@BoardID,@Name,@Description,@Message,@Category,
            @MedalURL,@RibbonURL,@SmallMedalURL,@SmallRibbonURL,
            @SmallMedalWidth,@SmallMedalHeight,@SmallRibbonWidth,@SmallRibbonHeight,
            @SortOrder,@Flags)

        select @@rowcount
    end
    else begin
        update [{databaseOwner}].[{objectQualifier}Medal]
            set [BoardID] = BoardID,
                [Name] = @Name,
                [Description] = @Description,
                [Message] = @Message,
                [Category] = @Category,
                [MedalURL] = @MedalURL,
                [RibbonURL] = @RibbonURL,
                [SmallMedalURL] = @SmallMedalURL,
                [SmallRibbonURL] = @SmallRibbonURL,
                [SmallMedalWidth] = @SmallMedalWidth,
                [SmallMedalHeight] = @SmallMedalHeight,
                [SmallRibbonWidth] = @SmallRibbonWidth,
                [SmallRibbonHeight] = @SmallRibbonHeight,
                [SortOrder] = @SortOrder,
                [Flags] = @Flags
        where [MedalID] = @MedalID

        select @@rowcount
    end

end
GO

create proc [{databaseOwner}].[{objectQualifier}user_listmedals]
    @UserID	int
as begin
        (select
        a.[MedalID],
        a.[Name],
        isnull(b.[Message], a.[Message]) as [Message],
        a.[MedalURL],
        a.[RibbonURL],
        a.[SmallMedalURL],
        isnull(a.[SmallRibbonURL], a.[SmallMedalURL]) as [SmallRibbonURL],
        a.[SmallMedalWidth],
        a.[SmallMedalHeight],
        isnull(a.[SmallRibbonWidth], a.[SmallMedalWidth]) as [SmallRibbonWidth],
        isnull(a.[SmallRibbonHeight], a.[SmallMedalHeight]) as [SmallRibbonHeight],
        [{databaseOwner}].[{objectQualifier}medal_getsortorder](b.[SortOrder],a.[SortOrder],a.[Flags]) as [SortOrder],
        [{databaseOwner}].[{objectQualifier}medal_gethide](b.[Hide],a.[Flags]) as [Hide],
        [{databaseOwner}].[{objectQualifier}medal_getribbonsetting](a.[SmallRibbonURL],a.[Flags],b.[OnlyRibbon]) as [OnlyRibbon],
        a.[Flags],
        b.[DateAwarded]
    from
        [{databaseOwner}].[{objectQualifier}Medal] a
        inner join [{databaseOwner}].[{objectQualifier}UserMedal] b on a.[MedalID] = b.[MedalID]
    where
        b.[UserID] = @UserID)

    union

    (select
        a.[MedalID],
        a.[Name],
        isnull(b.[Message], a.[Message]) as [Message],
        a.[MedalURL],
        a.[RibbonURL],
        a.[SmallMedalURL],
        isnull(a.[SmallRibbonURL], a.[SmallMedalURL]) as [SmallRibbonURL],
        a.[SmallMedalWidth],
        a.[SmallMedalHeight],
        isnull(a.[SmallRibbonWidth], a.[SmallMedalWidth]) as [SmallRibbonWidth],
        isnull(a.[SmallRibbonHeight], a.[SmallMedalHeight]) as [SmallRibbonHeight],
        [{databaseOwner}].[{objectQualifier}medal_getsortorder](b.[SortOrder],a.[SortOrder],a.[Flags]) as [SortOrder],
        [{databaseOwner}].[{objectQualifier}medal_gethide](b.[Hide],a.[Flags]) as [Hide],
        [{databaseOwner}].[{objectQualifier}medal_getribbonsetting](a.[SmallRibbonURL],a.[Flags],b.[OnlyRibbon]) as [OnlyRibbon],
        a.[Flags],
        NULL as [DateAwarded]
    from
        [{databaseOwner}].[{objectQualifier}Medal] a
        inner join [{databaseOwner}].[{objectQualifier}GroupMedal] b on a.[MedalID] = b.[MedalID]
        inner join [{databaseOwner}].[{objectQualifier}UserGroup] c on b.[GroupID] = c.[GroupID]
    where
        c.[UserID] = @UserID)
    order by
        [OnlyRibbon] desc,
        [SortOrder] asc

end
GO

create proc [{databaseOwner}].[{objectQualifier}user_medal_list]
    @UserID int = null,
    @MedalID int = null
as begin
        select
        a.[MedalID],
        a.[Name],
        a.[MedalURL],
        a.[RibbonURL],
        a.[SmallMedalURL],
        a.[SmallRibbonURL],
        a.[SmallMedalWidth],
        a.[SmallMedalHeight],
        a.[SmallRibbonWidth],
        a.[SmallRibbonHeight],
        b.[SortOrder],
        a.[Flags],
        c.[Name] as [UserName],
        c.[DisplayName] as [DisplayName],
        b.[UserID],
        isnull(b.[Message],a.[Message]) as [Message],
        b.[Message] as [MessageEx],
        b.[Hide],
        b.[OnlyRibbon],
        b.[SortOrder] as [CurrentSortOrder],
        b.[DateAwarded]
    from
        [{databaseOwner}].[{objectQualifier}Medal] a
        inner join [{databaseOwner}].[{objectQualifier}UserMedal] b on b.[MedalID] = a.[MedalID]
        inner join [{databaseOwner}].[{objectQualifier}User] c on c.[UserID] = b.[UserID]
    where
        (@UserID is null or b.[UserID] = @UserID) and
        (@MedalID is null or b.[MedalID] = @MedalID)
    order by
        c.[Name] ASC,
        b.[SortOrder] ASC

end
GO

/* Stored procedures for Buddy feature */

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}buddy_addrequest]
    @FromUserID INT,
    @ToUserID INT,
    @UTCTIMESTAMP datetime,
    @approved BIT = NULL OUT,
	@UseDisplayName BIT,
    @paramOutput NVARCHAR(255) = NULL OUT
AS
    BEGIN
        IF NOT EXISTS ( SELECT  ID
                        FROM    [{databaseOwner}].[{objectQualifier}Buddy]
                        WHERE   ( FromUserID = @FromUserID
                                  AND ToUserID = @ToUserID
                                ) )
            BEGIN
                IF ( NOT EXISTS ( SELECT    ID
                                  FROM      [{databaseOwner}].[{objectQualifier}Buddy]
                                  WHERE     ( FromUserID = @ToUserID
                                              AND ToUserID = @FromUserID
                                            ) )
                   )
                    BEGIN
                        INSERT  INTO [{databaseOwner}].[{objectQualifier}Buddy]
                                (
                                  FromUserID,
                                 ToUserID,
                                  Approved,
                                  Requested
                                )
                        VALUES  (
                                  @FromUserID,
                                  @ToUserID,
                                  0,
                                  @UTCTIMESTAMP
                                )
                        SET @paramOutput = ( SELECT (CASE WHEN @UseDisplayName = 1 THEN [DisplayName] ELSE [Name] END)
		                     FROM [{databaseOwner}].[{objectQualifier}User]
							 WHERE ( UserID = @ToUserID )
                           )
                        SET @approved = 0
                    END
                ELSE
                    BEGIN
                        INSERT  INTO [{databaseOwner}].[{objectQualifier}Buddy]
                                (
                                  FromUserID,
                                  ToUserID,
                                  Approved,
                                  Requested
                                )
                        VALUES  (
                                  @FromUserID,
                                  @ToUserID,
                                  1,
                                  @UTCTIMESTAMP
                                )
                        UPDATE  [{databaseOwner}].[{objectQualifier}Buddy]
                        SET     Approved = 1
                        WHERE   ( FromUserID = @ToUserID
                                  AND ToUserID = @FromUserID
                                )
                        SET @paramOutput = ( SELECT [Name]
                                             FROM   [{databaseOwner}].[{objectQualifier}User]
                                             WHERE  ( UserID = @ToUserID )
                                           )
                        SET @approved = 1
                    END
            END
        ELSE
            BEGIN
                SET @paramOutput = ''
                SET @approved = 0
            END
    END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}buddy_approverequest]
    @FromUserID INT,
    @ToUserID INT,
    @Mutual BIT,
    @UTCTIMESTAMP datetime,
	@UseDisplayName BIT,
    @paramOutput NVARCHAR(255) = NULL OUT
AS
    BEGIN
        IF EXISTS ( SELECT  ID
                    FROM    [{databaseOwner}].[{objectQualifier}Buddy]
                    WHERE   ( FromUserID = @FromUserID
                              AND ToUserID = @ToUserID
                            ) )
            BEGIN
                UPDATE  [{databaseOwner}].[{objectQualifier}Buddy]
                SET     Approved = 1
                WHERE   ( FromUserID = @FromUserID
                          AND ToUserID = @ToUserID
                        )
                SET @paramOutput = ( SELECT (CASE WHEN @UseDisplayName = 1 THEN [DisplayName] ELSE [Name] END)
		                     FROM [{databaseOwner}].[{objectQualifier}User]
							 WHERE ( UserID = @FromUserID )
                           )
                IF ( @Mutual = 1 )
                    AND ( NOT EXISTS ( SELECT   ID
                                       FROM     [{databaseOwner}].[{objectQualifier}Buddy]
                                       WHERE    FromUserID = @ToUserID
                                                AND ToUserID = @FromUserID )
                        )
                    INSERT  INTO [{databaseOwner}].[{objectQualifier}Buddy]
                            (
                              FromUserID,
                              ToUserID,
                              Approved,
                              Requested
                            )
                    VALUES  (
                              @ToUserID,
                              @FromUserID,
                              1,
                              @UTCTIMESTAMP
                            )
            END
    END
GO

    CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}buddy_list] @FromUserID INT
AS
    BEGIN
        SELECT  a.UserID,
                a.BoardID,
                a.[Name],
                a.Joined,
                a.NumPosts,
                RankName = b.Name,
                c.Approved,
                c.FromUserID,
                c.Requested,
                a.UserStyle,
                a.Suspended
        FROM   [{databaseOwner}].[{objectQualifier}User] a
                JOIN [{databaseOwner}].[{objectQualifier}Rank] b ON b.RankID = a.RankID
                JOIN [{databaseOwner}].[{objectQualifier}Buddy] c ON ( c.ToUserID = a.UserID
                                              AND c.FromUserID = @FromUserID
                                              and a.IsApproved = 1
                                            )
        UNION
        SELECT  @FromUserID AS UserID,
                a.BoardID,
                a.[Name],
                a.Joined,
                a.NumPosts,
                RankName = b.Name,
                c.Approved,
                c.FromUserID,
                c.Requested,
                a.UserStyle,
                a.Suspended
        FROM    [{databaseOwner}].[{objectQualifier}User] a
                JOIN [{databaseOwner}].[{objectQualifier}Rank] b ON b.RankID = a.RankID
                JOIN [{databaseOwner}].[{objectQualifier}Buddy] c ON ( ( c.Approved = 0 )
                                              AND ( c.ToUserID = @FromUserID )
                                              AND ( a.UserID = c.FromUserID )
                                              and a.IsApproved = 1
                                            )
        ORDER BY a.Name
    END
    GO

    CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}buddy_remove]
    @FromUserID INT,
    @ToUserID INT,
	@UseDisplayName BIT,
    @paramOutput NVARCHAR(255) = NULL OUT
AS
    BEGIN
        DELETE  FROM [{databaseOwner}].[{objectQualifier}Buddy]
        WHERE   ( FromUserID = @FromUserID
                  AND ToUserID = @ToUserID
                )
        SET @paramOutput = ( SELECT (CASE WHEN @UseDisplayName = 1 THEN [DisplayName] ELSE [Name] END)
		                     FROM [{databaseOwner}].[{objectQualifier}User]
							 WHERE ( UserID = @ToUserID )
                           )
    END
    GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}buddy_denyrequest]
    @FromUserID INT,
    @ToUserID INT,
	@UseDisplayName BIT,
    @paramOutput NVARCHAR(255) = NULL OUT
AS
    BEGIN
        DELETE  FROM [{databaseOwner}].[{objectQualifier}Buddy]
        WHERE   FromUserID = @FromUserID
                AND ToUserID = @ToUserID
        SET @paramOutput = ( SELECT (CASE WHEN @UseDisplayName = 1 THEN [DisplayName] ELSE [Name] END)
		                     FROM [{databaseOwner}].[{objectQualifier}User]
							 WHERE ( UserID = @FromUserID
							)
)
    END
Go
/* End of stored procedures for Buddy feature */

CREATE procedure [{databaseOwner}].[{objectQualifier}topic_favorite_details]
(   @BoardID int,
    @CategoryID int=null,
    @PageUserID int,
    @SinceDate datetime=null,
    @ToDate datetime,
    @PageIndex int = 1,
    @PageSize int = 0,
    @StyledNicks bit = 0,
    @FindLastRead bit = 0
)
AS
begin
   declare @TotalRows int
   declare @FirstSelectRowNumber int
   declare @LastSelectRowNumber int

   -- find total returned count
   select  @TotalRows = count(1)
        from
        [{databaseOwner}].[{objectQualifier}Topic] c
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=c.UserID
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x   on x.ForumID=d.ForumID
        join [{databaseOwner}].[{objectQualifier}Category] cat on cat.CategoryID=d.CategoryID
        JOIN [{databaseOwner}].[{objectQualifier}FavoriteTopic] z ON z.TopicID=c.TopicID AND z.UserID=@PageUserID
    where
        (c.LastPosted between @SinceDate and @ToDate) and
        x.UserID = @PageUserID and
        CONVERT(int,x.ReadAccess) <> 0 and
        cat.BoardID = @BoardID and
        (@CategoryID is null or cat.CategoryID=@CategoryID) and
        c.IsDeleted = 0

    select @PageIndex = @PageIndex+1;
    select @FirstSelectRowNumber = (@PageIndex - 1) * @PageSize + 1;
    select @LastSelectRowNumber = (@PageIndex - 1) * @PageSize + @PageSize;

    with TopicIds  as
     (
     select ROW_NUMBER() over (order by cat.SortOrder asc, d.SortOrder asc, c.LastPosted desc) as RowNum, c.TopicID
     from  [{databaseOwner}].[{objectQualifier}Topic] c
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x   on x.ForumID=d.ForumID
        join [{databaseOwner}].[{objectQualifier}Category] cat on cat.CategoryID=d.CategoryID
        JOIN [{databaseOwner}].[{objectQualifier}FavoriteTopic] z ON z.TopicID=c.TopicID AND z.UserID=@PageUserID
    where
        (c.LastPosted between @SinceDate and @ToDate) and
        x.UserID = @PageUserID and
        CONVERT(int,x.ReadAccess) <> 0 and
        cat.BoardID = @BoardID and
        (@CategoryID is null or cat.CategoryID=@CategoryID) and
        c.IsDeleted = 0
      )
      select
        c.ForumID,
        c.TopicID,
        c.TopicMovedID,
        c.Posted,
        LinkTopicID = IsNull(c.TopicMovedID,c.TopicID),
        [Subject] = c.Topic,
        [Description] = c.Description,
        [Status] = c.Status,
        [Styles] = c.Styles,
        c.UserID,
        Starter = IsNull(c.UserName,b.Name),
        StarterDisplay = IsNull(c.UserDisplayName, b.DisplayName),
        NumPostsDeleted = (SELECT COUNT(1) FROM [{databaseOwner}].[{objectQualifier}Message] mes WHERE mes.TopicID = c.TopicID AND mes.IsDeleted = 1 AND mes.IsApproved = 1 AND ((@PageUserID IS NOT NULL AND mes.UserID = @PageUserID) OR (@PageUserID IS NULL)) ),
        Replies = (select count(1) from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=c.TopicID and x.IsDeleted=0) - 1,
        [Views] = c.[Views],
        LastPosted = c.LastPosted,
        LastUserID = c.LastUserID,
        LastUserName = lastUser.Name,
        LastUserDisplayName = lastUser.DisplayName,
        LastMessageID = c.LastMessageID,
        LastMessageFlags = c.LastMessageFlags,
        LastTopicID = c.TopicID,
        TopicFlags = c.Flags,
        FirstMessage = (SELECT TOP 1 CAST([Message] as nvarchar(1000)) FROM [{databaseOwner}].[{objectQualifier}Message] mes2 where mes2.TopicID = IsNull(c.TopicMovedID,c.TopicID) AND mes2.Position = 0),
        FavoriteCount = (SELECT COUNT(ID) as [FavoriteCount] FROM [{databaseOwner}].[{objectQualifier}FavoriteTopic] WHERE TopicID = IsNull(c.TopicMovedID,c.TopicID)),
        c.Priority,
        c.PollID,
        ForumName = d.Name,
        c.TopicMovedID,
        ForumFlags = d.Flags,
        FirstMessage = (SELECT TOP 1 CAST([Message] as nvarchar(1000)) FROM [{databaseOwner}].[{objectQualifier}Message] mes2 where mes2.TopicID = IsNull(c.TopicMovedID,c.TopicID) AND mes2.Position = 0),
        StarterSuspended = b.Suspended,
        LastUserSuspended = lastUser.Suspended,
        StarterStyle = case(@StyledNicks)
            when 1 then  b.UserStyle
            else ''	 end,
        LastUserStyle= case(@StyledNicks)
            when 1 then  (select top 1 usr.[UserStyle] from [{databaseOwner}].[{objectQualifier}User] usr  where usr.UserID = c.LastUserID)
            else ''	 end,
        LastForumAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}ForumReadTracking] x WHERE x.ForumID=d.ForumID AND x.UserID = @PageUserID)
             else ''	 end,
        LastTopicAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}TopicReadTracking] y WHERE y.TopicID=c.TopicID AND y.UserID = @PageUserID)
             else ''	 end,
        TotalRows = @TotalRows,
        PageIndex = @PageIndex
    from
        TopicIds ti
        inner join [{databaseOwner}].[{objectQualifier}Topic] c on c.TopicID = ti.TopicID
        join [{databaseOwner}].[{objectQualifier}User] lastUser on lastUser.UserID = c.LastUserID
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=c.UserID
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
    where ti.RowNum between @FirstSelectRowNumber and @LastSelectRowNumber
        order by
            RowNum ASC
end
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}album_save]
    (
      @AlbumID INT = NULL,
      @UserID INT = null,
      @Title NVARCHAR(255) = NULL,
      @CoverImageID INT = NULL,
      @UTCTIMESTAMP datetime
    )
as
    BEGIN
        -- Update Cover?
        IF ( @CoverImageID IS NOT NULL
             AND @CoverImageID <> 0
           )
            UPDATE  [{databaseOwner}].[{objectQualifier}UserAlbum]
            SET     CoverImageID = @CoverImageID
            WHERE   AlbumID = @AlbumID
        ELSE
            --Remove Cover?
            IF ( @CoverImageID = 0 )
                UPDATE  [{databaseOwner}].[{objectQualifier}UserAlbum]
                SET     CoverImageID = NULL
                WHERE   AlbumID = @AlbumID
            ELSE
            -- Update Title?
                IF @AlbumID is not null
                    UPDATE  [{databaseOwner}].[{objectQualifier}UserAlbum]
                    SET     Title = @Title
                    WHERE   AlbumID = @AlbumID
                ELSE
                    BEGIN
                    -- New album. insert into table.
                        INSERT  INTO [{databaseOwner}].[{objectQualifier}UserAlbum]
                                (
                                  UserID,
                                  Title,
                                  CoverImageID,
                                  Updated
                                )
                        VALUES  (
                                  @UserID,
                                  @Title,
                                  @CoverImageID,
                                  @UTCTIMESTAMP
                                )
                        RETURN SCOPE_IDENTITY()
                    END
    END
    GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}album_getstats]
    @UserID INT = NULL,
    @AlbumID INT = NULL,
    @AlbumNumber INT = NULL OUTPUT,
    @ImageNumber BIGINT = NULL OUTPUT
as
    BEGIN
        IF @AlbumID IS NOT NULL
            SET @ImageNumber = ( SELECT COUNT(ImageID)
                                 FROM   [{databaseOwner}].[{objectQualifier}UserAlbumImage]
                                 WHERE  AlbumID = @AlbumID
                               )
        ELSE
            BEGIN
                SET @AlbumNumber = ( SELECT COUNT(AlbumID)
                                     FROM   [{databaseOwner}].[{objectQualifier}UserAlbum]
                                     WHERE  UserID = @UserID
                                   )
                SET @ImageNumber = ( SELECT COUNT(ImageID)
                                     FROM   [{databaseOwner}].[{objectQualifier}UserAlbumImage]
                                     WHERE  AlbumID in (
                                            SELECT  AlbumID
                                            FROM    [{databaseOwner}].[{objectQualifier}UserAlbum]
                                            WHERE   UserID = @UserID )
                                   )
            END
    END
    GO

CREATE procedure [{databaseOwner}].[{objectQualifier}album_image_list]
    (
      @AlbumID INT = NULL,
      @ImageID INT = null
    )
as
    BEGIN
        IF @AlbumID IS NOT null
            SELECT  *
            FROM    [{databaseOwner}].[{objectQualifier}UserAlbumImage]
            WHERE   AlbumID = @AlbumID
            ORDER BY Uploaded DESC
        ELSE
            SELECT  a.*,
                    b.UserID
            FROM    [{databaseOwner}].[{objectQualifier}UserAlbumImage] a
                    INNER JOIN [{databaseOwner}].[{objectQualifier}UserAlbum] b ON b.AlbumID = a.AlbumID
            WHERE   ImageID = @ImageID
    END
    GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}album_image_delete] ( @ImageID INT )
as
    BEGIN
        DELETE  FROM [{databaseOwner}].[{objectQualifier}UserAlbumImage]
        WHERE   ImageID = @ImageID
        UPDATE  [{databaseOwner}].[{objectQualifier}UserAlbum]
        SET     CoverImageID = NULL
        WHERE   CoverImageID = @ImageID
        UPDATE  [{databaseOwner}].[{objectQualifier}UserAlbum]
        SET     CoverImageID = NULL
        WHERE   CoverImageID = @ImageID
    END
    GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}user_getsignaturedata] (@BoardID INT, @UserID INT)
as
    BEGIN



DECLARE   @GroupData TABLE
(
    G_UsrSigChars int,
    G_UsrSigBBCodes nvarchar(4000),
    G_UsrSigHTMLTags nvarchar(4000)
)

   declare @ust int, @usbbc nvarchar(4000),
    @ushtmlt nvarchar(4000), @rust int, @rusbbc nvarchar(4000),
    @rushtmlt nvarchar(4000)

      declare c cursor for
      SELECT ISNULL(c.UsrSigChars,0), ISNULL(c.UsrSigBBCodes,''), ISNULL(c.UsrSigHTMLTags,'')
      FROM [{databaseOwner}].[{objectQualifier}User] a
                        JOIN [{databaseOwner}].[{objectQualifier}UserGroup] b
                          ON a.UserID = b.UserID
                            JOIN [{databaseOwner}].[{objectQualifier}Group] c
                              ON b.GroupID = c.GroupID
                              WHERE a.UserID = @UserID AND c.BoardID = @BoardID ORDER BY c.SortOrder ASC

        -- first check ranks
        SELECT TOP 1 @rust = ISNULL(c.UsrSigChars,0), @rusbbc = c.UsrSigBBCodes,
        @rushtmlt = c.UsrSigHTMLTags
        FROM [{databaseOwner}].[{objectQualifier}Rank] c
                                JOIN [{databaseOwner}].[{objectQualifier}User] d
                                  ON c.RankID = d.RankID
                                   WHERE d.UserID = @UserID AND c.BoardID = @BoardID
                                   ORDER BY c.RankID DESC
        open c

        fetch next from c into  @ust, @usbbc , @ushtmlt
        while @@FETCH_STATUS = 0
        begin
        if not exists (select top 1 1 from @GroupData)
        begin

        -- insert first row and compare with ranks data
    INSERT INTO @GroupData(G_UsrSigChars,G_UsrSigBBCodes,G_UsrSigHTMLTags)
        select (CASE WHEN @rust > ISNULL(@ust,0) THEN @rust ELSE ISNULL(@ust,0) END),
        (COALESCE(@rusbbc + ',','') + COALESCE(@usbbc,'')) ,(COALESCE(@rushtmlt + ',','') + COALESCE(@ushtmlt, '') )
        end
        else
        begin
        update @GroupData set
        G_UsrSigChars = (CASE WHEN G_UsrSigChars > COALESCE(@ust, 0) THEN G_UsrSigChars ELSE COALESCE(@ust, 0) END),
        G_UsrSigBBCodes = COALESCE(@usbbc + ',','') + G_UsrSigBBCodes,
        G_UsrSigHTMLTags = COALESCE(@ushtmlt + ',', '') + G_UsrSigHTMLTags
        end

        fetch next from c into   @ust, @usbbc , @ushtmlt

        end

       close c
       deallocate c


        SELECT
        UsrSigChars = G_UsrSigChars,
        UsrSigBBCodes = G_UsrSigBBCodes,
        UsrSigHTMLTags = G_UsrSigHTMLTags
        FROM @GroupData

   END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}user_getalbumsdata] (@BoardID INT, @UserID INT )
as
    BEGIN
    DECLARE
    @OR_UsrAlbums int,
    @OG_UsrAlbums int,
    @OR_UsrAlbumImages int,
    @OG_UsrAlbumImages int
     -- Ugly but bullet proof - it used very rarely
    DECLARE  @GroupData TABLE
(
    G_UsrAlbums int,
    G_UsrAlbumImages int
)
    DECLARE
   @RankData TABLE
(
    R_UsrAlbums int,
    R_UsrAlbumImages int
)

      -- REMOVED ORDER BY c.SortOrder ASC, SELECTING ALL

    INSERT INTO @GroupData(G_UsrAlbums,
    G_UsrAlbumImages)
    SELECT  ISNULL(c.UsrAlbums,0), ISNULL(c.UsrAlbumImages,0)
    FROM [{databaseOwner}].[{objectQualifier}User] a
                        JOIN [{databaseOwner}].[{objectQualifier}UserGroup] b
                          ON a.UserID = b.UserID
                            JOIN [{databaseOwner}].[{objectQualifier}Group] c
                              ON b.GroupID = c.GroupID
                              WHERE a.UserID = @UserID AND a.BoardID = @BoardID


     INSERT INTO @RankData(R_UsrAlbums, R_UsrAlbumImages)
     SELECT  ISNULL(c.UsrAlbums,0), ISNULL(c.UsrAlbumImages,0)
     FROM [{databaseOwner}].[{objectQualifier}Rank] c
                                JOIN [{databaseOwner}].[{objectQualifier}User] d
                                  ON c.RankID = d.RankID WHERE d.UserID = @UserID
                                  AND d.BoardID = @BoardID

       -- SELECTING MAX()

       SET @OR_UsrAlbums = (SELECT Max(R_UsrAlbums) FROM @RankData)
       SET @OG_UsrAlbums = (SELECT Max(G_UsrAlbums) FROM @GroupData)
       SET @OR_UsrAlbumImages = (SELECT Max(R_UsrAlbumImages) FROM @RankData)
       SET @OG_UsrAlbumImages = (SELECT Max(G_UsrAlbumImages) FROM @GroupData)

       SELECT
        NumAlbums  = (SELECT COUNT(ua.AlbumID) FROM [{databaseOwner}].[{objectQualifier}UserAlbum] ua
                      WHERE ua.UserID = @UserID),
        NumImages = (SELECT COUNT(uai.ImageID) FROM  [{databaseOwner}].[{objectQualifier}UserAlbumImage] uai
                     INNER JOIN [{databaseOwner}].[{objectQualifier}UserAlbum] ua
                     ON ua.AlbumID = uai.AlbumID
                     WHERE ua.UserID = @UserID),
        UsrAlbums = CASE WHEN @OG_UsrAlbums > @OR_UsrAlbums THEN @OG_UsrAlbums ELSE @OR_UsrAlbums END,
        UsrAlbumImages = CASE WHEN @OG_UsrAlbumImages > @OR_UsrAlbumImages THEN @OG_UsrAlbumImages ELSE @OR_UsrAlbumImages END


END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}messagehistory_list] (@MessageID INT, @DaysToClean INT,
      @UTCTIMESTAMP datetime)
as
    BEGIN
     -- delete all message variants older then DaysToClean days Flags reserved for possible pms
     delete from [{databaseOwner}].[{objectQualifier}MessageHistory]
     where DATEDIFF(day,Edited,@UTCTIMESTAMP ) > @DaysToClean

     SELECT 
	 mh.*, 
	 m.UserID, 
	 m.UserName, 
	 IsNull(m.UserDisplayName,(SELECT u.DisplayName FROM [{databaseOwner}].[{objectQualifier}User] u where u.UserID = m.UserID)) AS UserDisplayName, 
     editUser.UserStyle,
     editUser.Suspended,
	 t.ForumID, 
	 t.TopicID, 
	 t.Topic, 
	 m.Posted,
	 MessageIP = m.IP
     FROM [{databaseOwner}].[{objectQualifier}MessageHistory] mh
     LEFT JOIN [{databaseOwner}].[{objectQualifier}Message] m ON m.MessageID = mh.MessageID
     LEFT JOIN [{databaseOwner}].[{objectQualifier}Topic] t ON t.TopicID = m.TopicID
     LEFT JOIN [{databaseOwner}].[{objectQualifier}User] u ON u.UserID = t.UserID
     LEFT JOIN [{databaseOwner}].[{objectQualifier}User] editUser ON mh.EditedBy = editUser.UserID
     WHERE mh.MessageID = @MessageID
     order by mh.Edited, mh.MessageID
    END
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}user_lazydata](
    @UserID	int,
    @BoardID int,
    @ShowPendingBuddies bit = 0,
    @ShowUnreadPMs bit = 0,
    @ShowUserAlbums bit = 0,
    @ShowUserStyle bit = 0

) as
begin
    declare
    @G_UsrAlbums int,
    @R_UsrAlbums int,
    @R_Style varchar(255),
    @G_Style varchar(255)


    IF (@ShowUserAlbums > 0)
    BEGIN
    SELECT @G_UsrAlbums = ISNULL(MAX(c.UsrAlbums),0)
    FROM [{databaseOwner}].[{objectQualifier}User] a
                        JOIN [{databaseOwner}].[{objectQualifier}UserGroup] b
                          ON a.UserID = b.UserID
                            JOIN [{databaseOwner}].[{objectQualifier}Group] c
                              ON b.GroupID = c.GroupID
                               WHERE a.UserID = @UserID
                                 AND a.BoardID = @BoardID

    SELECT  @R_UsrAlbums = ISNULL(MAX(c.UsrAlbums),0)
    FROM [{databaseOwner}].[{objectQualifier}Rank] c
                                JOIN [{databaseOwner}].[{objectQualifier}User] d
                                  ON c.RankID = d.RankID WHERE d.UserID = @UserID
                                    AND d.BoardID = @BoardID
    END
    ELSE
    BEGIN
    SET @G_UsrAlbums = 0
    SET @R_UsrAlbums = 0
    END



    -- return information
    select TOP 1
        a.ProviderUserKey,
        UserFlags			= a.Flags,
        UserName			= a.Name,
        DisplayName			= a.DisplayName,
        Suspended			= a.Suspended,
		SuspendedReason     = a.SuspendedReason,
        ThemeFile			= a.ThemeFile,
        LanguageFile		= a.LanguageFile,
        TimeZoneUser		= a.TimeZone,
        CultureUser		    = a.Culture,
        IsGuest				= SIGN(a.IsGuest),
        IsDirty				= SIGN(a.IsDirty),
        ModeratePosts       = (select count(1)
                                from [{databaseOwner}].[{objectQualifier}Message] a
                                join [{databaseOwner}].[{objectQualifier}Topic] b ON a.TopicID=b.TopicID
                                join [{databaseOwner}].[{objectQualifier}Forum] c ON b.ForumID=c.ForumID
                                join [{databaseOwner}].[{objectQualifier}Category] d ON c.CategoryID=d.CategoryID
                                join [{databaseOwner}].[{objectQualifier}ActiveAccess] access on access.ForumID=b.ForumID
                                 where (a.Flags & 128)=128 and a.IsDeleted = 0 and b.IsDeleted = 0 and d.BoardID = @BoardID and CONVERT(int,access.ModeratorAccess)>0 and access.UserID=@UserID or 
                                       a.IsApproved=0 and a.IsDeleted = 0 and b.IsDeleted = 0 AND d.BoardID = @BoardID and CONVERT(int,access.ModeratorAccess)>0 and access.UserID=@UserID
                            ),
        ReceivedThanks      = (select count(1) from [{databaseOwner}].[{objectQualifier}Activity] where UserID=@UserID and (Flags & 1024)=1024 and Notification = 1),
		Mention             = (select count(1) from [{databaseOwner}].[{objectQualifier}Activity] where UserID=@UserID and (Flags & 512)=512 and Notification = 1),
        Quoted             = (select count(1) from [{databaseOwner}].[{objectQualifier}Activity] where UserID=@UserID and (Flags & 4096)=4096 and Notification = 1),
        UnreadPrivate		= CASE WHEN @ShowUnreadPMs > 0 THEN (select count(1) from [{databaseOwner}].[{objectQualifier}UserPMessage] where UserID=@UserID and IsRead=0 and IsDeleted = 0 and IsArchived = 0) ELSE 0 END,
        LastUnreadPm		= CASE WHEN @ShowUnreadPMs > 0 THEN (SELECT TOP 1 Created FROM [{databaseOwner}].[{objectQualifier}PMessage] pm INNER JOIN [{databaseOwner}].[{objectQualifier}UserPMessage] upm ON pm.PMessageID = upm.PMessageID WHERE upm.UserID=@UserID and upm.IsRead=0  and upm.IsDeleted = 0 and upm.IsArchived = 0 ORDER BY pm.Created DESC) ELSE NULL END,
        PendingBuddies      = CASE WHEN @ShowPendingBuddies > 0 THEN (SELECT COUNT(ID) FROM [{databaseOwner}].[{objectQualifier}Buddy] WHERE ToUserID = @UserID AND Approved = 0) ELSE 0 END,
        LastPendingBuddies	= CASE WHEN @ShowPendingBuddies > 0 THEN (SELECT TOP 1 Requested FROM [{databaseOwner}].[{objectQualifier}Buddy] WHERE ToUserID=@UserID and Approved = 0 ORDER BY Requested DESC) ELSE NULL END,
        UserStyle 		    = CASE WHEN @ShowUserStyle > 0 THEN (select top 1 usr.[UserStyle] from [{databaseOwner}].[{objectQualifier}User] usr  where usr.UserID = @UserID) ELSE '' END,
        NumAlbums  = (SELECT COUNT(1) FROM [{databaseOwner}].[{objectQualifier}UserAlbum] ua
        WHERE ua.UserID = @UserID),
        UsrAlbums  = (CASE WHEN @G_UsrAlbums > @R_UsrAlbums THEN @G_UsrAlbums ELSE @R_UsrAlbums END),
        UserHasBuddies  = SIGN(ISNULL((SELECT TOP 1 1 FROM [{databaseOwner}].[{objectQualifier}Buddy] WHERE [FromUserID] = @UserID OR [ToUserID] = @UserID),0)),
        -- Guest can't vote in polls attached to boards, we need some temporary access check by a criteria
        BoardVoteAccess	= (CASE WHEN a.Flags & 4 > 0 THEN 0 ELSE 1 END),
        Reputation         = a.Points
        from
           [{databaseOwner}].[{objectQualifier}User] a
        where
        a.UserID = @UserID
     end
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}message_GetTextByIds] (@MessageIDs varchar(max))
AS
    BEGIN
    -- vzrus says: the server version > 2000 ntext works too slowly with substring in the 2005
    DECLARE @ParsedMessageIDs TABLE
          (
                MessageID int
          )

    DECLARE @MessageID varchar(11), @Pos INT

    SET @Pos = CHARINDEX(',', @MessageIDs, 1)

    -- check here if the value is not empty
    IF REPLACE(@MessageIDs, ',', '') <> ''
    BEGIN
        WHILE @Pos > 0
        BEGIN
            SET @MessageID = LTRIM(RTRIM(LEFT(@MessageIDs, @Pos - 1)))
            IF @MessageID <> ''
            BEGIN
                  INSERT INTO @ParsedMessageIDs (MessageID) VALUES (CAST(@MessageID AS int)) --Use Appropriate conversion
            END
            SET @MessageIDs = RIGHT(@MessageIDs, LEN(@MessageIDs) - @Pos)
            SET @Pos = CHARINDEX(',', @MessageIDs, 1)
        END
        -- to be sure that last value is inserted
        IF (LEN(@MessageIDs) > 0)
               INSERT INTO @ParsedMessageIDs (MessageID) VALUES (CAST(@MessageIDs AS int))
        END

        SELECT a.MessageID, d.Message
            FROM @ParsedMessageIDs a
            INNER JOIN [{databaseOwner}].[{objectQualifier}Message] d ON (d.MessageID = a.MessageID)
    END
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}recent_users](@BoardID int,@TimeSinceLastLogin int,@StyledNicks bit=0) as
begin
    SELECT U.UserID,
    UserName = U.Name,
    UserDisplayName = U.DisplayName,
    IsCrawler = 0,
    UserCount = 1,
    IsHidden = (IsActiveExcluded),
    Style = CASE(@StyledNicks)
                WHEN 1 THEN U.UserStyle
                ELSE ''
            END,
    U.Suspended,
    U.LastVisit
    FROM [{databaseOwner}].[{objectQualifier}User] AS U
                JOIN [{databaseOwner}].[{objectQualifier}Rank] R on R.RankID=U.RankID
    WHERE (U.IsApproved = '1') AND
     U.BoardID = @BoardID AND
     (DATEADD(mi, 0 - @TimeSinceLastLogin, GETDATE()) < U.LastVisit) AND
                --Excluding guests
                NOT EXISTS(
                    SELECT 1
                        FROM [{databaseOwner}].[{objectQualifier}UserGroup] x
                            inner join [{databaseOwner}].[{objectQualifier}Group] y ON y.GroupID=x.GroupID
                        WHERE x.UserID=U.UserID and (y.Flags & 2)<>0
                    )
    ORDER BY U.LastVisit
end
GO

create procedure [{databaseOwner}].[{objectQualifier}readtopic_addorupdate](@UserID int,@TopicID int,
      @UTCTIMESTAMP datetime) as
begin

    declare	@LastAccessDate	datetime
    set @LastAccessDate = (select top 1 LastAccessDate from [{databaseOwner}].[{objectQualifier}TopicReadTracking] where UserID=@UserID AND TopicID=@TopicID)
    IF @LastAccessDate is not null
    begin
          update [{databaseOwner}].[{objectQualifier}TopicReadTracking] set LastAccessDate=@UTCTIMESTAMP where LastAccessDate = @LastAccessDate AND UserID=@UserID AND TopicID=@TopicID
    end
    ELSE
      begin
          insert into [{databaseOwner}].[{objectQualifier}TopicReadTracking](UserID,TopicID,LastAccessDate)
          values (@UserID, @TopicID, @UTCTIMESTAMP)
      end
end
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}readforum_addorupdate] (
    @UserID INT
    ,@ForumID INT,
      @UTCTIMESTAMP datetime
    )
AS
BEGIN
    DECLARE @LastAccessDate DATETIME

    IF EXISTS (
            SELECT 1
            FROM [{databaseOwner}].[{objectQualifier}ForumReadTracking]
            WHERE UserID = @UserID
                AND ForumID = @ForumID
            )
    BEGIN
        SET @LastAccessDate = (
                SELECT LastAccessDate
                FROM [{databaseOwner}].[{objectQualifier}ForumReadTracking]
                WHERE (
                        UserID = @UserID
                        AND ForumID = @ForumID
                        )
                )

        UPDATE [{databaseOwner}].[{objectQualifier}ForumReadTracking]
        SET LastAccessDate = @UTCTIMESTAMP
        WHERE LastAccessDate = @LastAccessDate
            AND UserID = @UserID
            AND ForumID = @ForumID
    END
    ELSE
    BEGIN
        INSERT INTO [{databaseOwner}].[{objectQualifier}ForumReadTracking] (
            UserID
            ,ForumID
            ,LastAccessDate
            )
        VALUES (
            @UserID
            ,@ForumID
            ,@UTCTIMESTAMP
            )
    END

    -- Delete TopicReadTracking for forum...
    DELETE
    FROM [{databaseOwner}].[{objectQualifier}TopicReadTracking]
    WHERE UserID = @UserID
        AND TopicID IN (
            SELECT TopicID
            FROM [{databaseOwner}].[{objectQualifier}Topic]
            WHERE ForumID = @ForumID
            )
END
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}topics_byuser]
(   @BoardID int,
    @CategoryID int=null,
    @PageUserID int,
    @SinceDate datetime=null,
    @ToDate datetime,
    @PageIndex int = 1,
    @PageSize int = 0,
    @StyledNicks bit = 0,
    @FindLastRead bit = 0
)
AS
begin
  declare @TotalRows int
   declare @FirstSelectRowNumber int
   declare @LastSelectRowNumber int
   -- find total returned count
   select  @TotalRows = count(1)
        from
        [{databaseOwner}].[{objectQualifier}Topic] c
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=c.UserID
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x   on x.ForumID=d.ForumID
        join [{databaseOwner}].[{objectQualifier}Category] cat on cat.CategoryID=d.CategoryID
    where
        (c.LastPosted between @SinceDate and @ToDate) and
        x.UserID = @PageUserID and
        CONVERT(int,x.ReadAccess) <> 0 and
        cat.BoardID = @BoardID and
        (@CategoryID is null or cat.CategoryID=@CategoryID) and
        c.IsDeleted = 0
        and	c.TopicMovedID is null
        and c.TopicID = (SELECT TOP 1 mess.TopicID FROM [{databaseOwner}].[{objectQualifier}Message] mess WHERE mess.UserID=@PageUserID AND mess.TopicID=c.TopicID)

    select @PageIndex = @PageIndex+1;
    select @FirstSelectRowNumber = (@PageIndex - 1) * @PageSize + 1;
    select @LastSelectRowNumber = (@PageIndex - 1) * @PageSize + @PageSize;

    with TopicIds  as
     (
     select ROW_NUMBER() over (order by cat.SortOrder asc, d.SortOrder asc, c.LastPosted desc) as RowNum, c.TopicID
     from  [{databaseOwner}].[{objectQualifier}Topic] c
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x   on x.ForumID=d.ForumID
        join [{databaseOwner}].[{objectQualifier}Category] cat on cat.CategoryID=d.CategoryID
  where
        (c.LastPosted between @SinceDate and @ToDate) and
        x.UserID = @PageUserID and
        CONVERT(int,x.ReadAccess) <> 0 and
        cat.BoardID = @BoardID and
        (@CategoryID is null or cat.CategoryID=@CategoryID) and
        c.IsDeleted = 0
        and	c.TopicMovedID is null
        and c.TopicID = (SELECT TOP 1 mess.TopicID FROM [{databaseOwner}].[{objectQualifier}Message] mess WHERE mess.UserID=@PageUserID AND mess.TopicID=c.TopicID)
      )
      select
        c.ForumID,
		ForumName = d.Name,
        c.TopicID,
        c.TopicMovedID,
        c.Posted,
        LinkTopicID = IsNull(c.TopicMovedID,c.TopicID),
        [Subject] = c.Topic,
        [Description] = c.Description,
        [Status] = c.Status,
        [Styles] = c.Styles,
        c.UserID,
        Starter = IsNull(c.UserName,b.Name),
        StarterDisplay = IsNull(c.UserDisplayName, b.DisplayName),
        NumPostsDeleted = (SELECT COUNT(1) FROM [{databaseOwner}].[{objectQualifier}Message] mes WHERE mes.TopicID = c.TopicID AND mes.IsDeleted = 1 AND mes.IsApproved = 1 AND ((@PageUserID IS NOT NULL AND mes.UserID = @PageUserID) OR (@PageUserID IS NULL)) ),
        Replies = (select count(1) from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=c.TopicID and x.IsDeleted=0) - 1,
        [Views] = c.[Views],
        LastPosted = c.LastPosted,
        LastUserID = c.LastUserID,
        LastUserName = lastUser.Name,
        LastUserDisplayName = lastUser.DisplayName,
        LastMessageID = c.LastMessageID,
        LastMessageFlags = c.LastMessageFlags,
        LastTopicID = c.TopicID,
        TopicFlags = c.Flags,
        FirstMessage = (SELECT TOP 1 CAST([Message] as nvarchar(1000)) FROM [{databaseOwner}].[{objectQualifier}Message] mes2 where mes2.TopicID = IsNull(c.TopicMovedID,c.TopicID) AND mes2.Position = 0),
        FavoriteCount = (SELECT COUNT(ID) as [FavoriteCount] FROM [{databaseOwner}].[{objectQualifier}FavoriteTopic] WHERE TopicID = IsNull(c.TopicMovedID,c.TopicID)),
        c.Priority,
        c.PollID,
        ForumName = d.Name,
        c.TopicMovedID,
        ForumFlags = d.Flags,
        FirstMessage = (SELECT TOP 1 CAST([Message] as nvarchar(1000)) FROM [{databaseOwner}].[{objectQualifier}Message] mes2 where mes2.TopicID = IsNull(c.TopicMovedID,c.TopicID) AND mes2.Position = 0),
        StarterSuspended = b.Suspended,
        LastUserSuspended = lastUser.Suspended,
        StarterStyle = case(@StyledNicks)
            when 1 then  b.UserStyle
            else ''	 end,
        LastUserStyle= case(@StyledNicks)
            when 1 then  (select top 1 usr.[UserStyle] from [{databaseOwner}].[{objectQualifier}User] usr  where usr.UserID = c.LastUserID)
            else ''	 end,
        LastForumAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}ForumReadTracking] x WHERE x.ForumID=d.ForumID AND x.UserID = @PageUserID)
             else ''	 end,
        LastTopicAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}TopicReadTracking] y WHERE y.TopicID=c.TopicID AND y.UserID = @PageUserID)
             else ''	 end,
        TotalRows = @TotalRows,
        PageIndex = @PageIndex
    from
        TopicIds ti
        inner join [{databaseOwner}].[{objectQualifier}Topic] c on c.TopicID = ti.TopicID
        join [{databaseOwner}].[{objectQualifier}User] lastUser on lastUser.UserID = c.LastUserID
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=c.UserID
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
    where ti.RowNum between @FirstSelectRowNumber and @LastSelectRowNumber
        order by
            RowNum ASC
end
GO

CREATE procedure [{databaseOwner}].[{objectQualifier}forum_move](@ForumOldID int,@ForumNewID int, @UTCTIMESTAMP datetime) as
begin
        -- Maybe an idea to use cascading foreign keys instead? Too bad they don't work on MS SQL 7.0...
    update [{databaseOwner}].[{objectQualifier}Forum] set LastMessageID=null,LastTopicID=null where ForumID=@ForumOldID
    update [{databaseOwner}].[{objectQualifier}Active] set ForumID=@ForumNewID where ForumID=@ForumOldID
    update [{databaseOwner}].[{objectQualifier}NntpForum] set ForumID=@ForumNewID where ForumID=@ForumOldID
    update [{databaseOwner}].[{objectQualifier}WatchForum] set ForumID=@ForumNewID where ForumID=@ForumOldID
    delete from [{databaseOwner}].[{objectQualifier}ForumReadTracking] where ForumID = @ForumOldID

    -- BAI CHANGED 02.02.2004
    -- Move topics, messages and attachments

    declare @tmpTopicID int;
    declare topic_cursor cursor for
        select TopicID from [{databaseOwner}].[{objectQualifier}Topic]
        where ForumID = @ForumOldID
        order by TopicID desc

    open topic_cursor

    fetch next from topic_cursor
    into @tmpTopicID

    -- Check @@FETCH_STATUS to see if there are any more rows to fetch.
    while @@FETCH_STATUS = 0
    begin
        exec [{databaseOwner}].[{objectQualifier}topic_move] @tmpTopicID,@ForumNewID,0, -1,@UTCTIMESTAMP;

       -- This is executed as long as the previous fetch succeeds.
        fetch next from topic_cursor
        into @tmpTopicID
    end

    close topic_cursor
    deallocate topic_cursor

    -- TopicMove finished
    -- END BAI CHANGED 02.02.2004

    delete from [{databaseOwner}].[{objectQualifier}ForumAccess] where ForumID = @ForumOldID

    --Update UserForums Too
    update [{databaseOwner}].[{objectQualifier}UserForum] set ForumID=@ForumNewID where ForumID=@ForumOldID
    --END ABOT CHANGED 09.04.2004
    delete from [{databaseOwner}].[{objectQualifier}Forum] where ForumID = @ForumOldID
end

GO

CREATE procedure [{databaseOwner}].[{objectQualifier}topic_unanswered]
(   @BoardID int,
    @CategoryID int=null,
    @PageUserID int,
    @SinceDate datetime=null,
    @ToDate datetime,
    @PageIndex int = 1,
    @PageSize int = 0,
    @StyledNicks bit = 0,
    @FindLastRead bit = 0
)
AS
begin
  declare @TotalRows int
   declare @FirstSelectRowNumber int
   declare @LastSelectRowNumber int

   -- find total returned count
   select  @TotalRows = count(1)
        from
        [{databaseOwner}].[{objectQualifier}Topic] c
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=c.UserID
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x   on x.ForumID=d.ForumID
        join [{databaseOwner}].[{objectQualifier}Category] cat on cat.CategoryID=d.CategoryID
    where
        c.LastPosted IS NOT NULL and (c.LastPosted between @SinceDate and @ToDate) and
        x.UserID = @PageUserID and
        CONVERT(int,x.ReadAccess) <> 0 and
        cat.BoardID = @BoardID and
        (@CategoryID is null or cat.CategoryID=@CategoryID) and
        c.IsDeleted = 0 and
        c.TopicMovedID is null and
        c.NumPosts = 1

    select @PageIndex = @PageIndex+1;
    select @FirstSelectRowNumber = (@PageIndex - 1) * @PageSize + 1;
    select @LastSelectRowNumber = (@PageIndex - 1) * @PageSize + @PageSize;

    with TopicIds  as
     (
     select ROW_NUMBER() over (order by cat.SortOrder asc, d.SortOrder asc, c.LastPosted desc) as RowNum, c.TopicID
     from  [{databaseOwner}].[{objectQualifier}Topic] c
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
        join [{databaseOwner}].[{objectQualifier}ActiveAccess] x   on x.ForumID=d.ForumID
        join [{databaseOwner}].[{objectQualifier}Category] cat on cat.CategoryID=d.CategoryID
    where
        c.LastPosted IS NOT NULL and (c.LastPosted between @SinceDate and @ToDate) and
        x.UserID = @PageUserID and
        CONVERT(int,x.ReadAccess) <> 0 and
        cat.BoardID = @BoardID and
        (@CategoryID is null or cat.CategoryID=@CategoryID) and
        c.IsDeleted = 0 and
        c.TopicMovedID is null and
        c.NumPosts = 1
      )
      select
        c.ForumID,
        c.TopicID,
        c.TopicMovedID,
        c.Posted,
        LinkTopicID = IsNull(c.TopicMovedID,c.TopicID),
        [Subject] = c.Topic,
        [Description] = c.Description,
        [Status] = c.Status,
        [Styles] = c.Styles,
        c.UserID,
        Starter = IsNull(c.UserName,b.Name),
        StarterDisplay = IsNull(c.UserDisplayName, b.DisplayName),
        NumPostsDeleted = (SELECT COUNT(1) FROM [{databaseOwner}].[{objectQualifier}Message] mes WHERE mes.TopicID = c.TopicID AND mes.IsDeleted = 1 AND mes.IsApproved = 1 AND ((@PageUserID IS NOT NULL AND mes.UserID = @PageUserID) OR (@PageUserID IS NULL)) ),
        Replies = (select count(1) from [{databaseOwner}].[{objectQualifier}Message] x where x.TopicID=c.TopicID and x.IsDeleted=0) - 1,
        [Views] = c.[Views],
        LastPosted = c.LastPosted,
        LastUserID = c.LastUserID,
        LastUserName = lastUser.Name,
        LastUserDisplayName = lastUser.DisplayName,
        LastMessageID = c.LastMessageID,
        LastMessageFlags = c.LastMessageFlags,
        LastTopicID = c.TopicID,
        TopicFlags = c.Flags,
        FirstMessage = (SELECT TOP 1 CAST([Message] as nvarchar(1000)) FROM [{databaseOwner}].[{objectQualifier}Message] mes2 where mes2.TopicID = IsNull(c.TopicMovedID,c.TopicID) AND mes2.Position = 0),
        FavoriteCount = (SELECT COUNT(ID) as [FavoriteCount] FROM [{databaseOwner}].[{objectQualifier}FavoriteTopic] WHERE TopicID = IsNull(c.TopicMovedID,c.TopicID)),
        c.Priority,
        c.PollID,
        ForumName = d.Name,
        c.TopicMovedID,
        ForumFlags = d.Flags,
        FirstMessage = (SELECT TOP 1 CAST([Message] as nvarchar(1000)) FROM [{databaseOwner}].[{objectQualifier}Message] mes2 where mes2.TopicID = IsNull(c.TopicMovedID,c.TopicID) AND mes2.Position = 0),
        StarterSuspended = b.Suspended,
        LastUserSuspended = lastUser.Suspended,
        StarterStyle = case(@StyledNicks)
            when 1 then  b.UserStyle
            else ''	 end,
        LastUserStyle= case(@StyledNicks)
            when 1 then  (select top 1 usr.[UserStyle] from [{databaseOwner}].[{objectQualifier}User] usr  where usr.UserID = c.LastUserID)
            else ''	 end,
        LastForumAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}ForumReadTracking] x WHERE x.ForumID=d.ForumID AND x.UserID = @PageUserID)
             else ''	 end,
        LastTopicAccess = case(@FindLastRead)
             when 1 then
               (SELECT top 1 LastAccessDate FROM [{databaseOwner}].[{objectQualifier}TopicReadTracking] y WHERE y.TopicID=c.TopicID AND y.UserID = @PageUserID)
             else ''	 end,
        TotalRows = @TotalRows,
        PageIndex = @PageIndex
    from
        TopicIds ti
        inner join [{databaseOwner}].[{objectQualifier}Topic] c on c.TopicID = ti.TopicID
        join [{databaseOwner}].[{objectQualifier}User] lastUser on lastUser.UserID = c.LastUserID
        join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=c.UserID
        join [{databaseOwner}].[{objectQualifier}Forum] d on d.ForumID=c.ForumID
    where ti.RowNum between @FirstSelectRowNumber and @LastSelectRowNumber
        order by
            RowNum ASC

end
GO

CREATE PROCEDURE [{databaseOwner}].[{objectQualifier}message_list_search](@ForumID int) AS
BEGIN
    select
        m.MessageID,
		m.[Message],
		m.Flags,
		m.Posted,
		ISNULL(m.UserDisplayName, u.DisplayName) as UserDisplayName,
        ISNULL(m.UserName, u.Name) as UserName,
		u.UserStyle,
        u.Suspended,
		m.UserID,
        t.TopicID,
		t.Topic,
        f.ForumID,
		f.Name,
		t.[Description]
    from
        [{databaseOwner}].[{objectQualifier}Forum] f
        join [{databaseOwner}].[{objectQualifier}Topic] t on t.ForumID = f.ForumID
		join [{databaseOwner}].[{objectQualifier}Message] m on m.TopicID = t.TopicID
		join  [{databaseOwner}].[{objectQualifier}User] u on u.UserID = m.UserID
    where
        f.ForumID=@ForumID and
		t.IsDeleted = 0 and
		m.IsDeleted = 0 and
		m.IsApproved = 1 and
		t.TopicMovedID is null 
    order by
        m.MessageID desc
END
GO

create procedure [{databaseOwner}].[{objectQualifier}mail_list]
(
    @TopicID int,
    @UserID int,
    @UTCTIMESTAMP datetime
)
AS
BEGIN
    select
        b.Email,
        b.Name,
        b.DisplayName,
        b.LanguageFile
    from
        [{databaseOwner}].[{objectQualifier}WatchTopic] a
        inner join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=a.UserID
    where
        b.UserID <> @UserID and
        b.NotificationType NOT IN (10, 20) AND
        a.TopicID = @TopicID and
        (a.LastMail is null or a.LastMail < b.LastVisit)
    UNION
    select
        b.Email,
        b.Name,
        b.DisplayName,
        b.LanguageFile
    from
        [{databaseOwner}].[{objectQualifier}WatchForum] a
        inner join [{databaseOwner}].[{objectQualifier}User] b on b.UserID=a.UserID
        inner join [{databaseOwner}].[{objectQualifier}Topic] c on c.ForumID=a.ForumID
    where
        b.UserID <> @UserID and
        b.NotificationType NOT IN (10, 20) AND
        c.TopicID = @TopicID and
        (a.LastMail is null or a.LastMail < b.LastVisit) and
        not exists(select 1 from [{databaseOwner}].[{objectQualifier}WatchTopic] x where x.UserID=b.UserID and x.TopicID=c.TopicID)

    update [{databaseOwner}].[{objectQualifier}WatchTopic] set LastMail = @UTCTIMESTAMP
    where TopicID = @TopicID
    and UserID <> @UserID

    update [{databaseOwner}].[{objectQualifier}WatchForum] set LastMail = @UTCTIMESTAMP
    where ForumID = (select ForumID from [{databaseOwner}].[{objectQualifier}Topic] where TopicID = @TopicID)
    and UserID <> @UserID
end
GO

create procedure [{databaseOwner}].[{objectQualifier}user_savestyle](@GroupID int, @RankID int)  as

begin
   update d
        set    d.UserStyle = ISNULL((select top 1 f.Style FROM [{databaseOwner}].[{objectQualifier}UserGroup] e
                                     join [{databaseOwner}].[{objectQualifier}Group] f on f.GroupID=e.GroupID
                                     WHERE f.Style IS NOT NULL and e.UserID = d.UserID order by f.SortOrder),
                                    (SELECT TOP 1 r.Style FROM [{databaseOwner}].[{objectQualifier}Rank] r
                                    join [{databaseOwner}].[{objectQualifier}User] u on u.RankID = r.RankID
                                    where u.UserID = d.UserID ))
        from  [{databaseOwner}].[{objectQualifier}User] d;

end
GO

create procedure [{databaseOwner}].[{objectQualifier}init_styles] as
begin
-- previously it was mangled so it's desirable update styles every time to be sure
exec('[{databaseOwner}].[{objectQualifier}user_savestyle] null,null')
end
GO

exec('[{databaseOwner}].[{objectQualifier}init_styles]')
GO
