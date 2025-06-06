import Foundation

struct Scripts {
    static func common(_ handlerName: String) -> String {
        """
        var dict = {};
        
        function byID(id) {
          return document.getElementById(id);
        }
        
        function byClass(className) {
          return document.getElementsByClassName(className);
        }
        
        function byTag(tag) {
          return document.getElementsByTagName(tag);
        }
        
        function byName(name) {
          return document.getElementsByName(name);
        }
        
        function bySelector(selector) {
          return document.querySelector(selector);
        }
        
        function bySelectorAll(selector) {
          return document.querySelectorAll(selector);
        }
        
        function imageToData(imageElement, scale) {
            var canvas = document.createElement("canvas");
            var context = canvas.getContext("2d");
            canvas.width = imageElement.width*scale;
            canvas.height = imageElement.height*scale;
            context.drawImage(imageElement, 0, 0);
            var imageData = canvas.toDataURL("image/jpeg");
            return imageData;
        }
        
        function postMessage(message) {
            window.webkit.messageHandlers.\(handlerName).postMessage(message);
        }
        """
    }
    
    static var advanced: String { """
        function getCaptchaImage() {
            var captchaImage = byID('c_default_ctl00_leftcolumn_loginuser_logincaptcha_CaptchaImage');
            dict["imageData"] = imageToData(captchaImage, 1);
            postMessage(dict);
        }
        
        function getProfileImage() {
            var profileImage = byID('ctl00_mainCopy_Foto');
            dict["profileImageData"] = imageToData(profileImage, 1.5);
            postMessage(dict);
        }
    """
    }
}
