Library "Roku_Ads.brs"

sub Main(params)
  ' Set video type
  videoContent = {
    streamFormat: "mp4"
  }
  videoContent.stream = {
    url: "http://video.ted.com/talks/podcast/DavidKelley_2002_480.mp4",
    bitrate: 800,
    quality: false
  }

  ' Drop the video into the videoScreen
  PlayContentWithAds(videoContent)
end sub

Function PlayVideoContent(content as Object) as Object
  ' roVideoScreen just closes if you try to resume or seek after ad playback
  videoScreen = CreateObject("roVideoScreen")

  ' Feed the content into the videoScreen
  videoScreen.SetContent(content)
  videoScreen.SetPositionNotificationPeriod(1)
  videoScreen.SetMessagePort(CreateObject("roMessagePort"))

  ' Show the video screen
  videoScreen.Show()
  return videoScreen
End Function

' Everything runs through here
Sub PlayContentWithAds(videoContent as Object)
  ' Create a canvas for the loading state
  canvas = CreateObject("roImageCanvas")
  canvas.SetLayer(1, {color: "#000000"})
  canvas.SetLayer(2, {text: "Loading..."})
  canvas.Show()

  ' Load the Roku ads library
  adIface = Roku_Ads()
  ' Print the version of the ad library
  print "Roku_Ads Library version: " + adIface.getLibraryVersion()

  'Set the publisher ad URL
  adIface.setAdUrl()

  ' Get the ads
  adPods = adIface.getAds()
  playContent = adIface.showAds(adPods) ' show preroll ad pod (if any)

  curPos = 0

  ' If the playContent exists, play the  video
  if playContent
    videoScreen = PlayVideoContent(videoContent)
  end if

  ' Set defaults
  closingContentScreen = false
  contentDone = false

End Sub
