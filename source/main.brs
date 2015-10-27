Library "Roku_Ads.brs"

sub Main(params)
    print "Device version " + GetDeviceVersion()
    ' lengthy (20+ min.) TED talk to allow time for testing multiple ad pods
    videoContent = { streamFormat : "mp4" }
    videoContent.stream = { url:  "http://video.ted.com/talks/podcast/DavidKelley_2002_480.mp4",
                            bitrate: 800,
                            quality: false
                          }
    PlayContentWithAds(videoContent)
end sub

Function PlayVideoContent(content as Object) as Object
    ' roVideoScreen just closes if you try to resume or seek after ad playback,
    ' so just create a new instance of the screen...
    videoScreen = CreateObject("roVideoScreen")
    videoScreen.SetContent(content)
    ' need a reasonable notification period set if midroll/postroll ads are to be
    ' rendered at an appropriate time
    videoScreen.SetPositionNotificationPeriod(1)
    videoScreen.SetMessagePort(CreateObject("roMessagePort"))
    videoScreen.Show()

    return videoScreen
End Function

Sub PlayContentWithAds(videoContent as Object)
    canvas = CreateObject("roImageCanvas")
    canvas.SetLayer(1, {color: "#000000"})
    canvas.SetLayer(2, {text: "Loading..."})
    canvas.Show()

    adIface = Roku_Ads()
    print "Roku_Ads library version: " + adIface.getLibVersion()
    ' Normally, would set publisher's ad URL here.  Otherwise uses default Roku ad server (with single preroll placeholder ad)
    adIface.setAdUrl("http://experiences.fuiszmedia.com/56252871e7d1690300cc0217/preview.html")

    adPods = adIface.getAds()
    playContent = adIface.showAds(adPods) ' show preroll ad pod (if any)

    curPos = 0
    if playContent
        videoScreen = PlayVideoContent(videoContent)
    end if

    closingContentScreen = false
    contentDone = false
    while playContent
        videoMsg = wait(0, videoScreen.GetMessagePort())
        if type(videoMsg) = "roVideoScreenEvent"
            if videoMsg.isStreamStarted()
                canvas.ClearLayer(2)
            end if
            if videoMsg.isPlaybackPosition()
                ' cache current playback position for resume after midroll ads
                curPos = videoMsg.GetIndex()
            end if

            if not closingContentScreen ' don't check for any more ads while waiting for screen close
                if videoMsg.isScreenClosed() ' roVideoScreen sends this message last for all exit conditions
                    playContent = false
               else if videoMsg.isFullResult()
                    contentDone = true ' don't want to resume playback after postroll ads
               end if

               ' check for midroll/postroll ad pods
               adPods = adIface.getAds(videoMsg)
               if adPods <> invalid and adPods.Count() > 0
                   ' must completely close content screen before showing ads
                   ' for some Roku platforms (e.g., RokuTV), calling Close() will not synchronously
                   ' close the media player and may prevent a new media player from being created
                   ' until the screen is fully closed (app has received the isScreenClosed() event)
                   videoScreen.Close()
                   closingContentScreen = true
               end if
            else if videoMsg.isScreenClosed()
                closingContentScreen = false ' now safe to render ads
            end if ' closingContentScreen

            if not closingContentScreen and adPods <> invalid and adPods.Count() > 0
                ' now safe to render midroll/postroll ads
                playContent = adIface.showAds(adPods)
                playContent = playContent and not contentDone
                if playContent
                    ' resume video playback after midroll ads
                    videoContent.PlayStart = curPos
                    videoScreen = PlayVideoContent(videoContent)
                end if
            end if ' !closingContentScreen
        end if ' roVideoScreenEvent
    end while
    if type(videoScreen) = "roVideoScreen" then videoScreen.Close()
End Sub
