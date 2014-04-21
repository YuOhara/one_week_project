 #!/usr/bin/env roseus
;;;
;;; euslisp version of ros_tutorials/rospy_tutorials/001_talker_listener
;;;

(ros::load-ros-manifest "roseus")
(ros::load-ros-manifest "leap_motion")

(ros::roseus "leap_listener")
;;(setq sys::*gc-hook* #'(lambda (a b) (format t ";; gc ~A ~A~%" a b)))

;; callback function
;(defun string-cb (msg) (print (list 'cb (sys::thread-self) (send msg :data))))
;(ros::subscribe "chatter" std_msgs::string #'string-cb)
 
; lambda function
;(ros::subscribe "chatter" std_msgs::string
;                #'(lambda (msg) (ros::rosinfo 
;                                 (format nil "I heard ~A" (send msg :data))))) 
;; method call
(defclass string-cb-class
  :super propertied-object
  :slots ())
(defmethod string-cb-class
  (:init () (ros::subscribe "leapmotion/data" leap_motion::leapros #'send self :string-cb))
					; kokomade
					;date ->direction nanikak
   (:string-cb (msg) 
	       (print (list 'cb self (send msg :palmpos :x)))
	       (setq palmpos (float-vector (* (send msg :palmpos :x) -5)
	       (* (send msg :palmpos :z) 5)
	       (* (send msg :palmpos :y) 5)))
	       (send cube1 :locate palmpos :world-pos)
	       (setq dif (v- palmpos cube2_pos))
	       (if (< (v. dif dif) 100000)
		   (setq cube2_pos (v+ cube2_pos (scale 0.1 (v- palmpos cube2_pos))))
		 )

	       (send cube2 :locate cube2_pos :world-pos)
	       (send *pr2* :inverse-kinematics (make-cascoords :pos cube2_pos) :revert-if-fail nil :stop 10)
	       (if (eq counter 100) 
		   (progn 
		   
		     (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
		     ;(send *ri* :angle-vector-sequence (list (send *pr2* :angle-vector)) (list 1000))
		     (send *ri* :wait-interpolation)
		     (setq counter 0)

		     )
)
	       (send *irtviewer* :draw-objects)
	       (x::window-main-one)

	       (setq counter (1+ counter))

	       )
   ))
(load "package://pr2eus/pr2-interface.l")
(pr2)
(pr2-init)
(sys::make-thread 2)
(setq counter 0)
(setq cube1 (make-cube 100 100 100))
(setq cube2 (make-cube 100 100 100))
(setq cube2_pos #f(500 500 500))
(send cube1 :set-color :red)
(send cube2 :set-color :yellow)
(objects (list *pr2* cube1 cube2))
(setq m (instance string-cb-class :init))

(defun sending ()
  (do-until-key
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
;    (send *ri* :wait-interpolation)
    (unix:sleep 1100)
))
;(sys::make-thread 2)
;(sys::thread-no-wait #'sending )

(do-until-key
  (ros::spin-once)
  ;;(sys::gc)
)
 ;(ros::spin)
