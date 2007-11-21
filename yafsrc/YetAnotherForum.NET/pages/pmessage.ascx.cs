/* Yet Another Forum.net
 * Copyright (C) 2003 Bj�rnar Henden
 * http://www.yetanotherforum.net/
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

using System;
using System.Data;
using System.Web.UI.WebControls;
using System.Text.RegularExpressions;
using System.Collections.Specialized;
using YAF.Classes.Utils;
using YAF.Classes.Data;
using YAF.Classes.UI;

namespace YAF.Pages
{
	/// <summary>
	/// Summary description for pmessage.
	/// </summary>
	public partial class pmessage : Classes.Base.ForumPage
	{
		protected Editor.ForumEditor Editor;

		public pmessage()
			: base( "PMESSAGE" )
		{
		}

		protected void Page_Init( object sender, EventArgs e )
		{
			Editor = YAF.Editor.EditorHelper.CreateEditorFromType( PageContext.BoardSettings.ForumEditor );
			EditorLine.Controls.Add( Editor );
		}

		protected void Page_Load( object sender, EventArgs e )
		{
			Editor.BaseDir = YafForumInfo.ForumRoot + "editors";
			Editor.StyleSheet = YafBuildLink.ThemeFile( "theme.css" );

			if ( User == null )
				YafBuildLink.Redirect( ForumPages.login, "ReturnUrl={0}", General.GetSafeRawUrl() );

			if ( !IsPostBack )
			{
				PageLinks.AddLink( PageContext.BoardSettings.Name, YafBuildLink.GetLink( ForumPages.forum ) );
				PageLinks.AddLink( PageContext.PageUserName, YafBuildLink.GetLink( ForumPages.cp_profile ) );
				PageLinks.AddLink( PageContext.Localization.GetText( ForumPages.cp_pm.ToString(), "TITLE" ), YafBuildLink.GetLink( ForumPages.cp_pm ) );
				PageLinks.AddLink( GetText( "TITLE" ) );

				Save.Text = GetText( "Save" );
				Preview.Text = GetText( "Preview" );
				Cancel.Text = GetText( "Cancel" );
				FindUsers.Text = GetText( "FINDUSERS" );
				AllUsers.Text = GetText( "ALLUSERS" );
				Clear.Text = GetText( "CLEAR" );

				AllUsers.Visible = PageContext.IsAdmin;

				if ( !String.IsNullOrEmpty( Request.QueryString ["p"] ) )
				{
					// PM is a reply or quoted reply (isQuoting)
					// to the given message id "p"
					bool isQuoting = Request.QueryString ["q"] == "1";

					DataTable dt = DB.pmessage_list( Security.StringToLongOrRedirect( Request.QueryString ["p"] ) );
					if ( dt.Rows.Count > 0 )
					{
						DataRow row = dt.Rows [0];
						int toUserId = ( int ) row ["ToUserID"];
						int fromUserId = ( int ) row ["FromUserID"];

						// verify access to this PM
						if ( toUserId != PageContext.PageUserID && fromUserId != PageContext.PageUserID )	YafBuildLink.AccessDenied();

						// handle subject
						string subject = ( string ) row ["Subject"];
						if ( !subject.StartsWith( "Re: " ) )
							subject = "Re: " + subject;
						Subject.Text = subject;

						// set "To" user and disable changing...
						To.Text = row ["FromUser"].ToString();
						To.Enabled = false;
						FindUsers.Enabled = false;
						AllUsers.Enabled = false;					

						if ( isQuoting )
						{
							// PM is a quoted reply
							string body = row ["Body"].ToString();
							bool isHtml = body.IndexOf( '<' ) >= 0;

							if ( PageContext.BoardSettings.RemoveNestedQuotes )
							{
								body = FormatMsg.RemoveNestedQuotes( body );
							}
							body = String.Format( "[QUOTE={0}]{1}[/QUOTE]", row ["FromUser"], body );
							Editor.Text = body.TrimStart();
						}
					}
				}
				else if ( !String.IsNullOrEmpty( Request.QueryString ["u"] ) )
				{
					// PM is being sent to a user
					int toUserId;
					if ( Int32.TryParse( Request.QueryString ["u"], out toUserId ) )
					{
						using ( DataTable dt = DB.user_list( PageContext.PageBoardID, toUserId, true ) )
						{
							To.Text = dt.Rows [0] ["Name"] as string;
							To.Enabled = false;
							FindUsers.Enabled = false;
							AllUsers.Enabled = false;
						}
					}
				}
				else
				{
					// Blank PM
				}
			}
		}

		protected void Save_Click( object sender, EventArgs e )
		{
			if ( To.Text.Length <= 0 )
			{
				PageContext.AddLoadMessage( GetText( "need_to" ) );
				return;
			}
			if ( ToList.Visible )
				To.Text = ToList.SelectedItem.Text;


			if ( ToList.SelectedItem != null && ToList.SelectedItem.Value == "0" )
			{
				string body = Editor.Text;
				MessageFlags tFlags = new MessageFlags();
				tFlags.IsHTML = Editor.UsesHTML;
				tFlags.IsBBCode = Editor.UsesBBCode;
				DB.pmessage_save( PageContext.PageUserID, 0, Subject.Text, body, tFlags.BitValue );
				YafBuildLink.Redirect( ForumPages.cp_profile );
			}
			else
			{
				using ( DataTable dt = DB.user_find( PageContext.PageBoardID, false, To.Text, null ) )
				{
					if ( dt.Rows.Count != 1 )
					{
						PageContext.AddLoadMessage( GetText( "NO_SUCH_USER" ) );
						return;
					}
					else if ( ( int ) dt.Rows [0] ["IsGuest"] > 0 )
					{
						PageContext.AddLoadMessage( GetText( "NOT_GUEST" ) );
						return;
					}

					if ( Subject.Text.Length <= 0 )
					{
						PageContext.AddLoadMessage( GetText( "need_subject" ) );
						return;
					}
					if ( Editor.Text.Length <= 0 )
					{
						PageContext.AddLoadMessage( GetText( "need_message" ) );
						return;
					}

					string body = Editor.Text;

					MessageFlags tFlags = new MessageFlags();
					tFlags.IsHTML = Editor.UsesHTML;
					tFlags.IsBBCode = Editor.UsesBBCode;

					DB.pmessage_save( PageContext.PageUserID, dt.Rows [0] ["UserID"], Subject.Text, body, tFlags.BitValue );

					if ( PageContext.BoardSettings.AllowPMEmailNotification )
						SendPMNotification( Convert.ToInt32( dt.Rows [0] ["UserID"] ), Subject.Text );

					YafBuildLink.Redirect( ForumPages.cp_profile );
				}
			}
		}

		private void SendPMNotification( int toUserID, string subject )
		{
			try
			{
				bool pmNotificationAllowed;
				string toEMail;

				using ( DataTable dt = DB.user_list( PageContext.PageBoardID, toUserID, true ) )
				{
					pmNotificationAllowed = ( bool ) dt.Rows [0] ["PMNotification"];
					toEMail = ( string ) dt.Rows [0] ["EMail"];
				}

				if ( pmNotificationAllowed )
				{
					int userPMessageID;
					//string senderEmail;

					// get the PM ID
					// Ederon : 11/21/2007 - PageBoardID as parameter of DB.pmessage_list?
					// using (DataTable dt = DB.pmessage_list(toUserID, PageContext.PageBoardID, null))
					using (DataTable dt = DB.pmessage_list(toUserID, null, null))
						userPMessageID = ( int ) dt.Rows [0] ["UserPMessageID"];

					// get the sender e-mail -- DISABLED: too much information...
					//using ( DataTable dt = YAF.Classes.Data.DB.user_list( PageContext.PageBoardID, PageContext.PageUserID, true ) )
					//	senderEmail = ( string ) dt.Rows [0] ["Email"];

					// send this user a PM notification e-mail
					StringDictionary emailParameters = new StringDictionary();

					emailParameters ["{fromuser}"] = PageContext.PageUserName;
					emailParameters ["{link}"] = String.Format( "{1}{0}\r\n\r\n", YafBuildLink.GetLink( ForumPages.cp_message, "pm={0}", userPMessageID ), YafForumInfo.ServerURL );
					emailParameters ["{forumname}"] = PageContext.BoardSettings.Name;
					emailParameters ["{subject}"] = subject;

					string message = General.CreateEmailFromTemplate( "pmnotification.txt", ref emailParameters );

					string emailSubject = string.Format( GetText( "COMMON", "PM_NOTIFICATION_SUBJECT" ), PageContext.PageUserName, PageContext.BoardSettings.Name, subject );

					//  Build a MailMessage
					General.SendMail( PageContext.BoardSettings.ForumEmail, toEMail, emailSubject, message );
				}
			}
			catch ( Exception x )
			{
				DB.eventlog_create( PageContext.PageUserID, this, x );
				PageContext.AddLoadMessage( String.Format( GetText( "failed" ), x.Message ) );
			}
		}

		protected void Preview_Click( object sender, EventArgs e )
		{
			PreviewRow.Visible = true;

			MessageFlags tFlags = new MessageFlags();
			tFlags.IsHTML = Editor.UsesHTML;
			tFlags.IsBBCode = Editor.UsesBBCode;

			string body = FormatMsg.FormatMessage( Editor.Text, tFlags );

			using ( DataTable dt = DB.user_list( PageContext.PageBoardID, PageContext.PageUserID, true ) )
			{
				if ( !dt.Rows [0].IsNull( "Signature" ) )
					body += "<br/><hr noshade/>" + FormatMsg.FormatMessage( dt.Rows [0] ["Signature"].ToString(), new MessageFlags() );
			}

			PreviewCell.InnerHtml = body;
		}

		protected void Cancel_Click( object sender, EventArgs e )
		{
			YafBuildLink.Redirect( ForumPages.cp_pm );
		}

		protected void FindUsers_Click( object sender, EventArgs e )
		{
			if ( To.Text.Length < 2 )
			{
				PageContext.AddLoadMessage( GetText( "NEED_MORE_LETTERS" ) );
				return;
			}

			using ( DataTable dt = DB.user_find( PageContext.PageBoardID, true, To.Text, null ) )
			{
				if ( dt.Rows.Count > 0 )
				{
					ToList.DataSource = dt;
					ToList.DataValueField = "UserID";
					ToList.DataTextField = "Name";
					ToList.DataBind();
					//ToList.SelectedIndex = 0;
					ToList.Visible = true;
					To.Visible = false;
					FindUsers.Visible = false;
					Clear.Visible = true;
				}
				DataBind();
			}
		}
		protected void AllUsers_Click( object sender, EventArgs e )
		{
			ListItem li = new ListItem( "All Users", "0" );
			ToList.Items.Add( li );
			ToList.Visible = true;
			To.Text = "All Users";
			To.Visible = false;
			FindUsers.Visible = false;
			AllUsers.Visible = false;
			Clear.Visible = true;
		}
		protected void Clear_Click( object sender, EventArgs e )
		{
			ToList.Items.Clear();
			ToList.Visible = false;
			To.Text = "";
			To.Visible = true;
			FindUsers.Visible = true;
			AllUsers.Visible = true;
			Clear.Visible = false;
		}
	}
}
