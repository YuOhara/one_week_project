 #!/usr/bin/env roseus
;;;
;;; euslisp version of ros_tutorials/rospy_tutorials/001_talker_listener
;;;

(ros::load-ros-manifest "roseus")
(ros::load-ros-manifest "leap_control")

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
  (:init () (ros::subscribe "leapmotion/data" leap_control::leapros #'send self :string-cb))
					; kokomade
					;date ->direction nanikak
   (:string-cb (msg) 
	       (setq hand_poss (send msg :points))
	       (setq hand_points3D nil)
	       (let ((x 0))
		 (dolist (pos hand_poss)
		   (setq hand_points3D (append hand_points3D (list (float-vector (* -5 (send pos :x)) (* 5 (send pos :z)) (* 5 (send pos :y))))))
		   (send (elt cube_hands x) :locate (float-vector (* -5 (send pos :x)) (* 5 (send pos :z)) (* 5 (send pos :y))):worldpos)
		   (setq x (+ x 1))
		   )
		 (while (> 10 x)
		   (send (elt cube_hands x) :locate #f(0 0 0) :worldpos)
		   (setq x (+ x 1))
		   )
		 )
	        
	       (format t "get data\n")
	       (dolist (arm '(:rarm :larm))  
					;(setq arm :larm) 
		 (setq temp_pos (send (send *pr2* arm :end-coords) :worldpos))
		 (setq det_pos temp_pos)
		 (dolist (hand_pos hand_points3D)
		   (setq dif (v- hand_pos temp_pos))
		   (if (< (v. dif dif) 100000)		   
		       (progn
			 (setq det_pos (v+ det_pos (scale 0.1 dif))) ;kokode minus mo ireru 	
			 )
		     )
		   )
		 (send *pr2* arm :inverse-kinematics (make-cascoords :pos det_pos) :revert-if-fail nil :stop 10 :rotational-axis nil)		   
		 )

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
   )

(load "package://pr2eus/pr2-interface.l")
(pr2)
(pr2-init)
(sys::make-thread 2)
(setq counter 0)
(setq cube_hands nil)
(dotimes (x 10) (setq cube_hands (append cube_hands (list (make-cube 100 100 100)))))
(dotimes (x 10) (send (elt cube_hands x) :set-color :red))

(objects (cons *pr2* cube_hands))
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

