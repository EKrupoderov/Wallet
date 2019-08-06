
/**  The CardView class defines the attributes and behavior of the cards that appear in WalletView objects. */
open class CardView: UIView {
    
    // MARK: Public methods
    
    /**
     Initializes and returns a newly allocated card view object with the specified frame rectangle.
     
     - parameter aRect: The frame rectangle for the card view, measured in points.
     - returns: An initialized card view.
     */
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupGestures()
    }
    
    /**
     Returns a card view object initialized from data in a given unarchiver.
     
     - parameter aDecoder: An unarchiver object.
     - returns: A card view, initialized using the data in decoder.
     */
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupGestures()
    }
    
    /**  A Boolean value that determines whether the view is presented. */
    open var presented: Bool = false
    
    
    /**  A parent wallet view object, or nil if the card view is not visible. */
    public var walletView: WalletView? {
        return container()
    }
    
    /** This method is called when the card view is tapped. */
    @objc open func tapped() {
        if let _ = walletView?.presentedCardView {
            walletView?.dismissPresentedCardView(animated: true)
        } else {
            walletView?.present(cardView: self, animated: true)
        }
    }
    
    /** This block is called to determine if a card view can be panned. */
    public var cardViewCanPanBlock: WalletView.CardViewShouldAllowBlock?
    
    /** This block is called to determine if a card view can be panned. */
    public var cardViewCanReleaseBlock: WalletView.CardViewShouldAllowBlock?
    
    /** This block is called when user interact with view. */
    public var cardInteractionBlock: WalletView.WalletViewInteractionBlock?
    
    private var calledCardViewBeganPanBlock = true
    /** This block is called when a card view began panning. */
    public var cardViewBeganPanBlock: WalletView.CardViewBeganPanBlock?
    
    /** This method is called when the card view is panned. */
    @objc open func panned(gestureRecognizer: UIPanGestureRecognizer) {
        
        switch gestureRecognizer.state {
        case .began:
            walletView?.grab(cardView: self, popup: false)
            calledCardViewBeganPanBlock = false
        case .changed:
            updateGrabbedCardViewOffset(gestureRecognizer: gestureRecognizer)
        default:
            if cardViewCanReleaseBlock?() == false {
                walletView?.layoutWalletView(animationDuration: WalletView.grabbingAnimationSpeed)
            } else {
                walletView?.releaseGrabbedCardView()
            }
        }
        
    }
    
    /** This method is called when the card view is long pressed. */
    @objc open func longPressed(gestureRecognizer: UILongPressGestureRecognizer) {
        
        switch gestureRecognizer.state {
        case .began:
            walletView?.grab(cardView: self, popup: true)
        case .changed: ()
        default:
            if cardViewCanReleaseBlock?() == false {
                walletView?.layoutWalletView(animationDuration: WalletView.grabbingAnimationSpeed)
            } else {
                walletView?.releaseGrabbedCardView()
            }
        }
        
        
    }
    
    public let tapGestureRecognizer    = UITapGestureRecognizer()
    public let panGestureRecognizer    = UIPanGestureRecognizer()
    public let longGestureRecognizer   = UILongPressGestureRecognizer()
    
    // MARK: Private methods
    
    func setupGestures() {
        
        tapGestureRecognizer.addTarget(self, action: #selector(CardView.tapped))
        tapGestureRecognizer.delegate = self
        addGestureRecognizer(tapGestureRecognizer)
        
        panGestureRecognizer.addTarget(self, action: #selector(CardView.panned(gestureRecognizer:)))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
        
        longGestureRecognizer.addTarget(self, action: #selector(CardView.longPressed(gestureRecognizer:)))
        longGestureRecognizer.delegate = self
        addGestureRecognizer(longGestureRecognizer)
        
    }
    
    
    func updateGrabbedCardViewOffset(gestureRecognizer: UIPanGestureRecognizer) {
        let offset = gestureRecognizer.translation(in: walletView).y
        if presented && offset > 0 {
            walletView?.updateGrabbedCardView(offset: offset)
            if cardViewCanPanBlock?() == true, calledCardViewBeganPanBlock == false {
                cardViewBeganPanBlock?()
                calledCardViewBeganPanBlock = true
            }
        } else if !presented {
            walletView?.updateGrabbedCardView(offset: offset)
        }
    }
    
}

extension CardView: UIGestureRecognizerDelegate {
    
    /**
     Asks the delegate if a gesture recognizer should begin interpreting touches.
     
     - parameter gestureRecognizer: An instance of a subclass of the abstract base class UIGestureRecognizer. This gesture-recognizer object is about to begin processing touches to determine if its gesture is occurring.
     */
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        cardInteractionBlock?()
        
        if gestureRecognizer == panGestureRecognizer {
            let cardViewCanPan = cardViewCanPanBlock?() ?? true
            if !cardViewCanPan {
                return false
            }
        }
        
        if gestureRecognizer == longGestureRecognizer && presented {
            return false
        } else if gestureRecognizer == panGestureRecognizer && !presented && walletView?.grabbedCardView != self {
            return false
        }
        
        return true
        
    }
    
    /**
     Asks the delegate if two gesture recognizers should be allowed to recognize gestures simultaneously.
     
     - parameter gestureRecognizer: An instance of a subclass of the abstract base class UIGestureRecognizer. This gesture-recognizer object is about to begin processing touches to determine if its gesture is occurring.
     - parameter otherGestureRecognizer: An instance of a subclass of the abstract base class UIGestureRecognizer.

     */
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer != tapGestureRecognizer && otherGestureRecognizer != tapGestureRecognizer
    }
    
    
}

internal extension UIView {
    
    func container<T: UIView>() -> T? {
        
        var view = superview
        
        while view != nil {
            if let view = view as? T {
                return view
            }
            view = view?.superview
        }
        
        return nil
    }
    
}
