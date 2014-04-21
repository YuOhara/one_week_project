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

	       (dolist (arm '(:rarm :larm))  ;suuzi de kannri sitahouga iikamo
					;(setq arm :larm) 
		 (setq temp_pos (send (send *pr2* arm :end-coords) :worldpos))
		 (setq det_pos temp_pos) ;;
		 (setq dif (v- palmpos temp_pos));kokode dolist
		 (if (< (v. dif dif) 100000)		   
		     (progn
		       (setq det_pos (v+ det_pos (scale 0.1 dif))) ;kokode minus mo ireru 	
		       )
		   )
		 (send *pr2* arm :inverse-kinematics (make-cascoords :pos det_pos) :revert-if-fail nil :stop 10 :rotational-axis nil)		   
		 )
	       (send cube2 :locate det_pos :world-pos)
	       ;tikaitoki hanasu 
	       ;append de mokuhyoutoru
	       ;koremadenoha sekirryokude hyougenn
	       (if (eq counter 100) 
		   (progn 
		     (format t "before send *ri* ")
					;  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
					;(send *ri* :angle-vector-sequence (list (send *pr2* :angle-vector)) (list 1000))
	;	     (send *ri* :wait-interpolation)
		     (format t "after send *ri* ")
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
(setq cube2_pos (send (send *pr2* :larm :end-coords) :worldpos))
(send cube1 :set-color :red)
(send cube2 :set-color :yellow)
(objects (list *pr2* cube1 cube2))
(setq m (instance string-cb-class :init))

(defun sending ()
  (do-until-key
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
;    (send *ri* :wait-interpolation)
    (unix:sleep 1000)
))
;(sys::make-thread 2)
;(sys::thread-no-wait #'sending )

(do-until-key
  (ros::spin-once)
  ;;(sys::gc)
)
 ;(ros::spin)

